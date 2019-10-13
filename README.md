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

