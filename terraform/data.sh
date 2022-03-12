#!/bin/bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io git python3 python3-pip
sudo usermod -aG docker ubuntu
git clone https://github.com/ihor-chaban/bombardier-automate.git /home/ubuntu/bombardier-automate
pip3 install -r /home/ubuntu/bombardier-automate/bombardier-automate/requirements.txt
nohup /home/ubuntu/bombardier-automate/bombardier-automate/bombardier-automate.py &