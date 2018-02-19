#!/bin/bash

set -e
set -x

#install Nix package manager
sudo yum -y install bzip2
sudo mkdir /nix
sudo chown ec2-user:ec2-user /nix
bash <(curl https://nixos.org/nix/install)
source /home/ec2-user/.nix-profile/etc/profile.d/nix.sh

#download cardano
cd /home/ec2-user
sudo yum -y install git
git clone https://github.com/input-output-hk/cardano-sl.git
cd /home/ec2-user/cardano-sl
git checkout master
git pull origin master

#set up config
sudo mkdir -p /etc/nix
sudo sh -c 'echo "binary-caches            = https://cache.nixos.org https://hydra.iohk.io
binary-cache-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" > /etc/nix/nix.conf'

#install cardano-sl
cd /home/ec2-user/cardano-sl
nix-build -A cardano-sl-wallet --cores 0 --max-jobs 2 --no-build-output --out-link master
nix-build -A connectScripts.mainnetWallet -o connect-to-mainnet

#move everything into an appropriate directory
mkdir /home/ec2-user/cardano
cd /home/ec2-user/cardano
cp /home/ec2-user/cardano-sl/master/bin/* /home/ec2-user/cardano/
mkdir /home/ec2-user/cardano/node
cp /home/ec2-user/cardano-sl/node/configuration.yaml /home/ec2-user/cardano/node/configuration.yaml
cp /home/ec2-user/cardano-sl/connect-to-mainnet /home/ec2-user/cardano/connect-to-mainnet

#install the service file
sudo sh -c 'echo "[Unit]
Description=Cardano-SL Node
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/cardano
ExecStart=/home/ec2-user/cardano/connect-to-mainnet
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/cardano-node.service'
sudo systemctl enable cardano-node

#start the node
sudo service cardano-node start
