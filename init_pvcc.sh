#!/bin/bash

VCP_JUPYTER=vcp-jupyter.sh
VCP_SDK_VERSION=25.10.0
JUPYTER_NOTEBOOK_PASSWORD=$(cat /dev/urandom | base64 | fold -w 10 | head -n 1)
DC_CMD="docker compose"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <Network IF Name>"
  exit 1
fi

if [ ! -f config/vpn_catalog.yml ]; then
  echo "Setup config file first: config/vpn_catalog.yml"
  exit 1
fi

LOCAL_NETWORK_IF=$1

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

cat << EOF > config/vpn_catalog.yml
cci_version: '1.0'
EOF

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
sed -i '/^VCP_VCC_PRIVATE_IPMASK/d' .env
echo "VCP_VCC_PRIVATE_IPMASK=$VCP_VCC_PRIVATE_IPMASK" >> .env

mkdir -p cert
cp dummy_cert/* cert/
sudo ${DC_CMD} up -d nginx occtr
sudo ${DC_CMD} exec -T occtr ./init.sh
sudo ${DC_CMD} exec -T occtr ./create_token.sh > tokenrc

# install VCP-Jupyter Notebook (include VCP SDK)
echo "$JUPYTER_NOTEBOOK_PASSWORD" > .jupyter_pass
port=8888
subdir=jupyter
jupyter_release=20250401-ssl-cc
sudo bash $VCP_JUPYTER $JUPYTER_NOTEBOOK_PASSWORD $port $subdir $VCP_SDK_VERSION $jupyter_release

for i in {1..10}
do
  http_code=$(curl -s -o /dev/null -w '%{http_code}' \
    "http://localhost:$port/jupyter/login?next=%2Fjupyter%2Ftree%3F" || echo 000)
  if [ 200 -eq "$http_code" ]; then
    break
  fi
  echo "Jupyter not ready. Retrying ... (${i})"
  sleep 2
done

container_name=cloudop-notebook-$VCP_SDK_VERSION-$subdir-$port
sudo docker cp cert/ca.pem $container_name:/usr/local/share/ca-certificates/vcp_ca.crt
sudo docker exec -u root $container_name update-ca-certificates

# output VCP API token
echo VCP REST API token: `cat tokenrc`
echo Jupyter login pass: `cat .jupyter_pass`

echo "setup was completed."