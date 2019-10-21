#!/bin/bash
git clone -b monolith https://github.com/express42/reddit.git
cd /home/appuser/reddit && bundle install
systemctl enable puma.service
systemctl start puma.service 

