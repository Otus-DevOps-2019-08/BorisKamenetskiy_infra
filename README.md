# BorisKamenetskiy_infra
BorisKamenetskiy Infra repository

2019-10-06
Added following config to reach someinternalhost through the bastion host:
Host *
  IdentityFile ~/.ssh/id_ecdsa
  User ubuntu
Host bastion
  Hostname 35.242.200.16
Host someinternalhost
  Hostname 10.156.0.3
  ProxyCommand ssh bastion -W %h:%p
  LocalForward 8080 127.0.0.1:8080

bastion_IP = 35.242.200.16
someinternalhost_IP = 10.156.0.3

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

2019-10-19
What was done:
- ADC installed;
- packer template created in ubuntu16.json file:
  - builder for ubuntu-1604 image with parameterized project_id (required), source_image_family (required), machine_type, image_description, disk_size, disk_type, network, tags. Required variables are set in variables.json file;
  - provisioner, which installs ruby and MongoDb;
  - added new json script immutable.json for homework with star;
  - added script monolith.sh for deployment of the application on the remote machine;
  - puma service file created and added to /etc/systemd/system. In provisioner this file is copied to the remote machine to be able to run puma service there;
  - created script create-reddit-vm.sh to run virtual machine from the created reddit-full image, created startup script - start_puma.sh. 

2019-10-27
What was done (homework terraform-1):
- new branch terraform-1 created;
- main configuration file created, there we have creation of google compute instance, firewall rule, provisioners to deploy our application and start puma server on the target machine;
- variables for parameterizing of main.tf created for project, public_key_path, private_key_path, disk_image, zone. Additional file variables.tf to add input variables is added. For zone default value is added. File terraform.tfvars is created to define some of those variables;
- file terraform.tfvars.example added;
- .gitignore appended in accordance with homework task;
- application works - tested by trying http://35.198.68.63:9292/.

