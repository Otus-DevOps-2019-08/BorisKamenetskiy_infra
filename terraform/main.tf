terraform {
  # Версия terraform
  required_version = "0.12.8"
}

provider "google" {
  # Версия провайдера
  version = "2.15"

  # ID проекта
  project = var.project

  region = var.region
}

resource "google_compute_project_metadata_item" "default" {
  key = "appuser1"
  value = "${file(var.public_key_path)}"
}

resource "google_compute_project_metadata_item" "appuser2"{
  key = "appuser2"
  value = "${file(var.public_key_path)}"
}

resource "google_compute_project_metadata_item" "appuser3"{
  key = "appuser3"
  value = "${file(var.public_key_path)}"
}

resource "google_compute_instance" "app" {
  count = var.inst_count
  name         = "reddit-app${count.index}"
  machine_type = "g1-small"
  zone         = var.zone
  tags         = ["reddit-app","allow-health-checks"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    # путь до публичного ключа
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  # Название сети, в которой действует правило
  network = "default"
  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]
  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["reddit-app"]
}

resource "google_compute_instance_group" "test" {
  name = "terraform-test"
  zone = var.zone

  instances = "${google_compute_instance.app.*.self_link}"
}

