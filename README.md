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
What was done (homework terraform-2):
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

2019-11-16
What was done (homework "ansible-1"):
- ansible and pip installed;
- infrastructure created in GCP via terraform stage script;
- ansible inventory created for appserver (35.235.42.81) and dbserver (35.198.68.63);
- ckecked how ping module works with both hosts;
- ansible.cfg, which contains path to the inventory file, remote_user, private_key file, created;
- command -a uptime checked;
- inventory file changed to reflect [app] and [db] groups;
- inventory.yml written;
- versions of ruby, bundler and mongod checked on the hosts using ansible;
- commands command, shell, systemd, service tried;
- module git tried;
- clone.yml implemented;
- after "ansible app -m command -a 'rm -rf ~/reddit'" and running playbook once again changed was equal to 1.

Issues:
- I have tried to implement the dynamic inventory and found gce.py as an example, but, as I don't know Python, it was too difficult for me to understand how it works (taking limited time into account). As I understand the idea of dynamic inventory, I should obtain list of all hosts with their IPs without knowing them beforehand (as it is in static inventory). I ended up with inventory.json for static inventory. If I had to implement the dynamic inventory, I would, probably, use existing modules.

2019-11-24
What was done (homework ansible-2):
- reddit_app.yml(with app configured) and  mongod.conf.j2 to parameterize Mongod config created;
- tag db-tag added;
- handler to restart mongod added;
- directory files with puma.service created, tasks to copy puma.service and to enable puma added to playbook. Corresponding sections are tagged with app-tag;
- handler for reloading puma added;
- template db_config.j2 added in templates directory, database url defined;
- corresponding task to copy template added to playbook, db_host variable defined;
- tasks for installation of bundle and cloning git added to playbook with tag deploy-tag;
- application works (34.76.75.106:9292);
- tasks of one scenarion transformed into several scenarios - for app, db and deploy in reddit_app2.yml. Tags and other important things are transferred to the definition of scenario;
- application works;
- created app.yml, db.yml, deploy.yml. Related parts are taken from reddit_app2.yml. reddit_app.yml is renamed to reddit_app_one_play.yml, reddit_app2.yml - to reddit_app_multiple_plays.yml;
- site.yml created. There management of all our configuration (app.yml, db.yml, deploy.yml) is defined via import command;
- application works;
- dynamic inventory created (see inventory.compute.gcp.yml), groups added, service account key added. Checked, that relevant IPs of app and db machines are propagated to ansible inventory and used in playbooks. Didn't take time to propagate internal IP address of db machine there. Checked, that application works fine with dynamic inventory file;
- packer_app.yml (install Ruby and Bundler) and packer_db.yml (add MongoDB, install it and enable service)  created to change provisioning part in packer/app.json and packer/db.json.

Issues:
- last bullet from homework (changing provisioning part of app.json and db.json) doesn't work for me because of some ssh-related issue, which seems to be not connected with packer/ansible (which work separately). My repository worked fine for Stanislav Sturov and for the moment I completely can't find, why this doesn't work for me. As I perceive it as blocker, which is not completely connected with the topic of homework itself, I decided to move further with homeworks for now. 

2019-11-24
What was done (homework ansible-3):
- folder roles created with sub-folders app and db;
- role structure applied both to app and db sub-folders;
- tasks from app.yml and db.yml migrated to roles/app/tasks/main.yml and roles/db/tasks/main.yml, correspondingly;
- mongodb template copied to roles/db/templates;
- corresponding handlers transferred from app.yml and db.yml to roles/app/handlers/main.yml and roles/db/handlers/main.yml, correspondingly. src path eliminated, as folder structure in role is taken into account;
- default variables from app.yml and db.yml created in roles/app/defaults/main.yml and roles/db/defaults/main.yml;
- db_config.j2 copied from ansible/templates to ansible/roles/app/templates;
- ansible/files/puma.service copied to ansible/roles/app/files;
- now in app.yml and db.yml we are only calling corresponding roles (app and db) and we still have variables in these files;
- everything works fine;
- directory environments with sub-directories stage and prod created;
- inventory file copied to stage and prod sub-directories from the previous bullet;
- ansible.cfg changed and now points to stage inventory file;
- sub-directories group_vars for sub-directories stage and prod created;
- variables migrated from app.yml to the new files in sub-directories stage/group_vars/app and prod/group_vars/app;
- stage/group_vars/all and prod/group_vars/all created with content "env: stage" and "env: prod", default information about environment added to app/defaults/main.yml and db/defaults/main.yml;
- tasks to show, in which environment we are working, added to app/tasks/main.yml and db/tasks/main.yml;
- directory ansible is cleaned up: now all playbooks are stored in directory playbooks and everything else (except for ansible.cfg and requirements.txt - in the directory old);
- ansible.cfg improved - location of roles added, as well as the opportunity to show diff between current output and output before changes;
- everything works fine on stage (every time, while making any experiments, I have destroyed infrastructure and re-created it using terraform; afterwards I have amended external and internal IP addresses of app and db hosts in inventory and group_vars/app);
- everything works fine on prod as well;
- community role jdauphant.nginx installed (information, required in order to fulfil it, was added to the new files requirements.txt in stage and prod directories), jdauphant.nginx added to .gitignore;
- variables, required for minimal configuration of jdauphant.nginx, added to stage/group_vars/app and prod/group_vars/app (and port in both cases is set to 9292 - for reddit application);
- port 80 opened in firewall rule for puma server in modules/app/main.tf;
- calling of role jdauphant.nginx added to app.yml playbook;
- applied site.yml playbook - application works now both on port 9292 and on port 80;
- file vault.key with some random string created in ansible directory, this very file added to .gitignore;
- playbook users.yml created in ansible/playbooks/ folder;
- two files with user credentials (credentials.yml) created in ansible/environments/stage and ansible/environments/prod in accordance with gist;
- corresponding files from the previous bullet are successfully encrypted using vault.key;
- calling of users.yml added to site.yml;
- checked, that users were created on app host with corresponding password;
- tried to read encrypted files using ansible-vault edit - everything is as expected.

Issues:
- permissions to my ansible directory were set by me to 777 and that leaded to the situation, when my ansible.cfg file was ignored. After I changed permissions of ansible directory to 755, everything started working (before I had ssh-related issues).

