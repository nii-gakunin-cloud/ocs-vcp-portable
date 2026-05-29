#!/bin/bash

VCP_JUPYTER=vcp-jupyter.sh
VCP_SDK_VERSION=26.10.0
JUPYTER_NOTEBOOK_PASSWORD=$(cat /dev/urandom | base64 | fold -w 10 | head -n 1)
DC_CMD="docker compose"
CONFIG_DIR='config'
CREDENTIALS_DIR='cred'
CERTS_DIR='cert'
CERT_FILE="$CERTS_DIR/occtr_cert.pem"
VCC_CMD='vcc'

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <Network IF Name>"
  exit 1
fi

vpn_catalog="$CONFIG_DIR/vpn_catalog.yml"
if [ ! -f $vpn_catalog ]; then
  echo "Setup config file first: $vpn_catalog"
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
    VERSION_STRING=5:27.4.0-1~ubuntu.$(. /etc/os-release && echo "$VERSION_ID")~$(. /etc/os-release && echo "$VERSION_CODENAME")
    sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
    sudo gpasswd -a $(whoami) docker
fi

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
sed -i '/^VCP_VCC_PRIVATE_IPMASK/d' .env
echo "VCP_VCC_PRIVATE_IPMASK=$VCP_VCC_PRIVATE_IPMASK" >> .env

# Create dummy cert for VCC and Jupyter Notebook
bash tools/create_dummy_cert.sh "$CERTS_DIR" 3600

sudo ${DC_CMD} up -d nginx occtr
sudo ${DC_CMD} exec -T occtr $VCC_CMD init

# install VCP-Jupyter Notebook (include VCP SDK)
port=8888
subdir=jupyter
jupyter_release=20251001-ssl-cc
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
sudo docker cp "$CERT_FILE" $container_name:/usr/local/share/ca-certificates/vcp_ca.crt
sudo docker exec -u root $container_name update-ca-certificates

# output VCP API token

sudo apt-get -y autoremove

echo "setup was completed."

msg=$(cat <<EOM
Your Jupyter password is:\n ${JUPYTER_NOTEBOOK_PASSWORD}\n
Initial vcc access token is:\n  $(sudo ${DC_CMD} exec -T occtr ${VCC_CMD} create_token)\n

Please note it down. This window will close and destroy the text upon pressing OK.
EOM
)
whiptail --title "Initial Passwords" \
         --msgbox "$msg" 15 60

unset JUPYTER_NOTEBOOK_PASSWORD