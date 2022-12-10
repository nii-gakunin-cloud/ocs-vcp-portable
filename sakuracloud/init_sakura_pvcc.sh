#!/bin/bash

VCP_JUPYTER_VERSION=22.10.0
JUPYTER_NOTEBOOK_PASSWORD=handson2212

EXIT_NETWORK_IF=eth0
LOCAL_NETWORK_IF=eth1

set -euo pipefail

sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily.service
sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer

# setup NAT router
echo net.ipv4.ip_forward=1 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -A POSTROUTING -o $EXIT_NETWORK_IF -j MASQUERADE
 
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

VCP_VCC_PRIVATE_IPMASK=$(ip --oneline --family inet address show dev $LOCAL_NETWORK_IF|awk '{print $4}')
sed -i '/^VCP_VCC_PRIVATE_IPMASK/d' .env
echo "VCP_VCC_PRIVATE_IPMASK=$VCP_VCC_PRIVATE_IPMASK" >> .env

# for handson 22.12
sudo apt-get -qq install -y netplan.io

# for handson 22.12
cat << EOF > config/vpn_catalog.yml
cci_version: '1.0'
sakura:
  default:
    sakura_local_switch_id: "000000000000"
    sakura_zone: is1b
    sakura_private_subnet_gateway_ip: 192.168.1.254
    private_network_ipmask: 192.168.1.0/24
EOF

# for handson 22.12
cat << EOF > config/sakura_config.yml
default:
  prefix_len: 24
  ip_addresses:
    - 192.168.1.12
    - 192.168.1.13
    - 192.168.1.14
    - 192.168.1.15
    - 192.168.1.16
EOF

cp dummy_cert/* cert/
sudo docker-compose up -d nginx occtr
sudo docker-compose exec -T occtr ./init.sh
sudo docker-compose exec -T occtr ./create_token.sh | tee tokenrc

# install VCP-Jupyter Notebook (include VCP SDK)
sudo bash vcp-jupyter-$VCP_JUPYTER_VERSION.sh $JUPYTER_NOTEBOOK_PASSWORD
sleep 5
http_code=$(curl localhost:8888/jupyter/login?next=%2Fjupyter%2Ftree%3F -w '%{http_code}\n' -o /dev/null -s)
test "$http_code" -eq 200

sudo docker cp cert/ca.pem cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888:/usr/local/share/ca-certificates/vcp_ca.crt
sudo docker exec cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888 update-ca-certificates

# for handson 22.12
sudo docker cp tokenrc cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888:/notebooks/notebook/token.txt
sudo docker cp SETUP_handson2212.ipynb cloudop-notebook-$VCP_JUPYTER_VERSION-jupyter-8888:/notebooks/notebook/SETUP.ipynb

# output VCP API token
echo VCP REST API token: `cat tokenrc`

echo "setup was completed."

