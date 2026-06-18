#!/bin/bash

DC_CMD="docker compose"
CONFIG_DIR='config'
CREDENTIALS_DIR='cred'
CERTS_DIR='cert'
CERT_FILE="$CERTS_DIR/occtr_cert.pem"
VCC_CMD='vcc'

vpn_catalog="$CONFIG_DIR/vpn_catalog.yml"
if [ ! -f $vpn_catalog ]; then
  echo "Setup config file first: $vpn_catalog"
  exit 1
fi

set -euo pipefail

sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# install docker if not installed
if [ -z $(which docker) ]; then
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
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo gpasswd -a $(whoami) docker
fi

# Create dummy cert for VCC and Jupyter Notebook
bash tools/create_dummy_cert.sh "$CERTS_DIR" 3600

sudo ${DC_CMD} up -d

# install VCP-Jupyter Notebook (include VCP SDK)
port=8888
subdir=jupyter

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
if [ 200 -ne "$http_code" ]; then
  echo "Failed to start Jupyter Notebook. HTTP status code: $http_code"
  exit 1
fi

sudo apt-get -y autoremove
echo "setup was completed."
echo "Jupyter is available at http://localhost:$port/jupyter/ ."
echo "Default password is shown in container log."
