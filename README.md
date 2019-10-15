# BorisKamenetskiy_infra
BorisKamenetskiy Infra repository

2019-10-06
Added following config to reach someinternalhost through the bastion host:
Host *
  IdentityFile ~/.ssh/id_ecdsa
  User ubuntu
Host bastion
  Hostname 35.210.154.75
Host someinternalhost
  Hostname 10.132.0.4
  ProxyCommand ssh bastion -W %h:%p
  LocalForward 8080 127.0.0.1:8080

bastion_IP = 35.210.154.75
someinternalhost_IP = 10.132.0.4

2019-10-07
Added following scripts to config new instance in gcloud
install_ruby.sh
install_mongodb.sh
deploy.sh
Those scripts are unified in the common script startup_script.sh
Command to run this script is:
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  startup-script = BorisKamenetskiy_Infra/startup_script.sh

Firewall rule:
gcloud compute firewall-rules create default-puma-server --allow tcp:9292 --target-tags puma-server

Connection data:
testapp_IP = 34.76.124.126
testapp_port = 9292

