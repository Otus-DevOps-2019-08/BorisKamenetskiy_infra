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
