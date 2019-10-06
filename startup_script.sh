#!/bin/sh
script_name=$0
script_full_path=$(dirname "$0")

echo "script_name: $script_name"
echo "full path: $script_full_path"
sudo BorisKamenetskiy_infra/install_ruby.sh
sudo BorisKamenetskiy_infra/install_mongodb.sh
sudo BorisKamenetskiy_infra/deploy.sh

