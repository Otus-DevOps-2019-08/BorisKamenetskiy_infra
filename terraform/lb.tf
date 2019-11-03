resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = "${google_compute_target_http_proxy.default.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "default" {
  name        = "test-proxy"
  url_map     = "${google_compute_url_map.urlmap.self_link}"
}

resource "google_compute_url_map" "urlmap" {
  name        = "urlmap"
  description = "a description"

  default_service = "${google_compute_backend_service.default.self_link}"
}

resource "google_compute_backend_service" "default" {
  name          = "backend-service"
  health_checks = ["${google_compute_health_check.http-health-check.self_link}"]

  backend {
    group = "${google_compute_instance_group.test.self_link}"
  }
}

resource "google_compute_firewall" "firewall_health_checks" {
  name = "allow-health-checks"
  # Название сети, в которой действует правило
  network = "default"
  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  # Каким адресам разрешаем доступ
  source_ranges = ["35.191.0.0/16","130.211.0.0/22"]
  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["allow-health-checks"]
}

# resource "google_compute_http_health_check" "http-health-check" {
#  name               = "http-health-check"
#  request_path       = "/"
#  check_interval_sec = 1
#  timeout_sec        = 1
#}

resource "google_compute_health_check" "http-health-check" {
  name = "http-health-check"
  description = "Health check via http"

  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 5

  http_health_check {
    port_name = "health-check-port"
    port_specification = "USE_NAMED_PORT"
    # host = "1.2.3.4"
    request_path = "/"
    proxy_header = "NONE"
    response = "I AM HEALTHY"
  }
}

