#!/bin/bash

VCP_JUPYTER=vcp-jupyter-25.04.0.sh
VCP_SDK_VERSION=23.04.0
JUPYTER_NOTEBOOK_PASSWORD=passw0rd

LOCAL_NETWORK_IF=ens160

set -euo pipefail

sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer

# install docker-ce
sudo apt-get -qq update
sudo apt-get -qq install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -qq update
sudo apt-get -qq install -y docker-ce docker-ce-cli containerd.io
sudo docker version

# install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose 

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
