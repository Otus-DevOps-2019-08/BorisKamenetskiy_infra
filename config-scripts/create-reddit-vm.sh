#!/bin/bash

gcloud compute instances create reddit-full --image reddit-full-boris-kamenetskiy --tags puma-server,http-server,https-server --metadata-from-file startup-script=/home/ubuntu/BorisKamenetskiy_infra/packer/scripts/start_puma.sh

