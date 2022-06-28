#!/bin/bash

PORTABLE_VCC_VERSION=22.04.1-rc0
VCP_JUPYTER_VERSION=22.04.0
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

# install VCP Portable Controller
curl -O https://vcpdev-debug.s3.ap-northeast-1.amazonaws.com/portable-vcc-rc/portable-vcc-$PORTABLE_VCC_VERSION.tgz
tar xf portable-vcc-$PORTABLE_VCC_VERSION.tgz
cd portable-vcc-$PORTABLE_VCC_VERSION/

cat << EOF > config/vpn_catalog.yml
cci_version: '1.0'
onpremises:
  default: {}
EOF

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
sed -i '/^VCP_VCC_PRIVATE_IPMASK/d' .env
echo "VCP_VCC_PRIVATE_IPMASK=$VCP_VCC_PRIVATE_IPMASK" >> .env

cp dummy_cert/* cert/
sudo docker-compose up -d nginx occtr
sudo docker-compose exec -T occtr ./init.sh
sudo docker-compose exec -T occtr ./create_token.sh | tee tokenrc

# install VCP-Jupyter Notebook (include VCP SDK)
sudo bash vcp-jupyter-$VCP_JUPYTER_VERSION.sh $JUPYTER_NOTEBOOK_PASSWORD
http_code=$(curl localhost:8888/jupyter/login?next=%2Fjupyter%2Ftree%3F -w '%{http_code}\n' -o /dev/null -s)
test "$http_code" -eq 200

sudo docker cp cert/ca.pem cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888:/usr/local/share/ca-certificates/vcp_ca.crt
sudo docker exec cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888 update-ca-certificates

# output VCP API token
echo VCP REST API token: `cat tokenrc`

