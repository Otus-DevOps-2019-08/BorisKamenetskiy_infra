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
- application works - tested by trying http://35.198.68.63:9292/;
- task with *: added 3 google_compute_project_metadata_items for appuser1, appuser2, appuser 3. I had to choose different names for all of them. Keys successfully added to the metadata in GCloud GUI;
- via GUI added appuser_web - no issues with terraform apply;
- now added second instance 35.235.47.25. puma service works on both instances;
- adding load balancer 34.102.189.35 (file lb.tf): google_compute_global_forwarding_rule, google_compute_target_http_proxy, google_compute_url_map, google_compute_backend_service (which was connected to google_compute_instance_group with both instances enlisted and to google_compute_health_check), ip address of the load balancer was added to output.tf (ip_address taken from google_compute_global_forwarding_rule);
- I have added inst_count variable to variables.tf with default value, equal to 1 and also to terraform.tfvars and terraform.tfvars.example, where defined inst_count = 2. Then I have created both compute instances using count. I had to add ${count.index} to the name field inside the google_compute_instance. Also I havechanged how instances are described in google_compute_inctance_group:  instances = "${google_compute_instance.app.*.self_link}". The most difficult thing was tooutput ip's of instances, which were obtained using count. Finally I have done it as it is visible in outputs.tf.

Issues observed:
- needed to degrade terraform version from 0.12.12 to 0.12.8. Link in the homework is to the newest version - not the same as in homework;
- obtained following error in the end of terraform apply stdout:
"google_compute_instance.app (remote-exec): Post-install message from capistrano3-puma:
google_compute_instance.app (remote-exec):     All plugins need to be explicitly installed with install_plugin.
google_compute_instance.app (remote-exec):     Please see README.md
google_compute_instance.app (remote-exec): Failed to execute operation: Invalid argument
Error: error executing "/tmp/terraform_1756125471.sh": Process exited with status 1" - don't understand, how to resolve it, though application works at http://35.198.68.63:9292/. This error was because of unneeded "'" in puma.service file, hence, "enable puma.service" didn't work;
- I had a lot of issues with health checks - they didn't pass. The reason was I needed to use google_compute_health_check with specified port 9292;
- Also I observed an issue with not reaching puma servie via load balancer IP. That was because I didn't add port_name in google_compute_backend_service and named_port with name "puma" and port "9292" - to google_compute_instance_group. After I have added those items, I have checked, that load balancer started working properly, with either puma on instance 1 disabled or puma on instance 2 disabled. By the way, that would be great to see somehow in application on the screen, which machine is actually working behind the loadbalancer;
- Spent more than hour, trying to figure out how to add instances, created by count in output.tf.

In general, this load balancing scheme has following point of failure: load balancer itself.

2019-11-10
What was done (homework ttrraform-2):
- tried importing existing infrastructure to terraform;
- tried using attributes of another resource;
- tried using packer and terraform together (packer provides images with installed ruby (app.json), mongodb (db.json) and terraform performs deployment based on those images). Created app.tf for vm with ruby and db.tf for vm with mongodb. Variables for image name added;
- vpc.tf created with "default-allow-ssh" firewall rule. After that only "provide" definition remains in main.tf;
- configuration applied. Application checked (that they are running) on the corresponding hosts;
- modules created: for app (in corresponding folder), for db, for vpc. In each folder we have the same set of files: main.tf, variables.tf, outputs.tf. Corresponding variables defined in variables.tf. Outpus.tf changed accordingly;
- sections to call modules added to main.tf. "terraform get" used to load modules;
- outputs.tf changed to reflect existing resources;
- access to created via "terraform apply" resources checked;
- source_ranges for ip addresses, from which access to hosts should be available, parameterized. Checked for 0.0.0.0/0, for some random IP and for my own IP. For my own IP there was no access for some reason;
- stage and prod folders with relevant set of files created. Paths to modules changed accordingly. Access from all IP addresses allowed to stage and only from my IP address - to PROD;
- unnecessary files removed from terraform directory;
- storage bucket module from HashiCorp terraform registry used (as compared to gist in homework slides, location should be added to module "storage bucket"). Resource created and visible in google cloud console;
- added backend.tf with backend configuration to stage and prod so, that terraform.tfstate is stored in the bucket in gcloud;
- checked how "terraform apply" works without tfstate file.

Issues:
- in db.tf and app.tf there should be "metadata = {..." and not "metadata {...".The same goes to access_config. Please, fix that in slides;
- output of app_external_ip is empty;
- there was no access to the created hosts with ruby and mongodb from my own IP address for some reason.   

