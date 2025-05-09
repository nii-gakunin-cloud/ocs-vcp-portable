#!/bin/bash

VCP_JUPYTER=vcp-jupyter.sh
VCP_SDK_VERSION=25.04.0
JUPYTER_NOTEBOOK_PASSWORD=passw0rd

EXIT_NETWORK_IF=eth0
LOCAL_NETWORK_IF=eth1

# 引数の数をチェック
if [ "$#" -ne 3 ]; then
  echo "Error: Exactly 3 arguments are required."
  echo "Usage: bash ./sakuracloud/init_sakura_pvcc.sh <SWITCH_ID> <ZONE_ID> <PRIVATE_NETWORK>"
  echo "Sample: bash ./sakuracloud/init_sakura_pvcc.sh 12345678912 is1b 172.23.1.0/24"
  exit 1
fi

SWITCH_ID=${1:?}
ZONE_ID=${2:?}
PRIVATE_NETWORK=${3:?}

if [ ! -e ./config/sakura_config.yml ]; then
  echo "Plugin data file is required: config/sakura_config.yml"
  exit 1
fi

set -euo pipefail

sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer

# setup NAT router
if ! grep -q "net.ipv4.ip_forward=1" "/etc/sysctl.conf"; then
  echo net.ipv4.ip_forward=1 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
  sudo iptables -P FORWARD ACCEPT
  sudo iptables -t nat -A POSTROUTING -o $EXIT_NETWORK_IF -j MASQUERADE
fi

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
cat <<EOF > /etc/netplan/99-$LOCAL_NETWORK_IF.yaml
network:
  version: 2
  ethernets:
    "$LOCAL_NETWORK_IF":
      addresses: [$VCP_VCC_PRIVATE_IPMASK]
EOF

sudo chmod 600 /etc/netplan/99-ens4.yaml
sudo chmod 600 /etc/netplan/01-netcfg.yaml
sudo netplan apply

# setup vpn_catalog
cat << EOF > config/vpn_catalog.yml
cci_version: '1.0'
onpremises:
  default: {}
sakura:
  default:
    sakura_local_switch_id: "$SWITCH_ID"
    sakura_private_subnet_gateway_ip: ${VCP_VCC_PRIVATE_IPMASK%%/*}
    sakura_zone: $ZONE_ID
    private_network_ipmask: $PRIVATE_NETWORK
EOF

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
