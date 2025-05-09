#!/bin/bash

VCP_JUPYTER=vcp-jupyter.sh
VCP_SDK_VERSION=25.04.0
JUPYTER_NOTEBOOK_PASSWORD=passw0rd

LOCAL_NETWORK_IF=ens160

set -euo pipefail

sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

# install docker
VERSION_STRING=5:27.4.0-1~ubuntu.$(. /etc/os-release && echo "$VERSION_ID")~$(. /etc/os-release && echo "$VERSION_CODENAME")
sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

# setup VC Controller
cd $(dirname $0)/..

cat << EOF > config/vpn_catalog.yml
cci_version: '1.0'
onpremises:
  default: {}
EOF

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
sed -i '/^VCP_VCC_PRIVATE_IPMASK/d' .env
echo "VCP_VCC_PRIVATE_IPMASK=$VCP_VCC_PRIVATE_IPMASK" >> .env

mkdir -p cert
cp dummy_cert/* cert/
sudo docker-compose up -d nginx occtr
sudo docker-compose exec -T occtr ./init.sh
sudo docker-compose exec -T occtr ./create_token.sh > tokenrc

# install VCP-Jupyter Notebook (include VCP SDK)
port=8888
subdir=jupyter
jupyter_release=20250401-ssl-cc
sudo bash $VCP_JUPYTER $JUPYTER_NOTEBOOK_PASSWORD $port $subdir $VCP_SDK_VERSION $jupyter_release
sleep 5
http_code=$(curl localhost:8888/jupyter/login?next=%2Fjupyter%2Ftree%3F -w '%{http_code}\n' -o /dev/null -s)
test "$http_code" -eq 200

container_name=cloudop-notebook-$VCP_SDK_VERSION-$subdir-$port
sudo docker cp cert/ca.pem $container_name:/usr/local/share/ca-certificates/vcp_ca.crt
sudo docker exec $container_name update-ca-certificates

# output VCP API token
echo VCP REST API token: `cat tokenrc`

echo "setup was completed."
