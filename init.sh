#!/bin/bash

CIDR=$(ip -o -4 addr show | grep -v ' lo' | awk '{print $4}' | head -n 1)
IP=${CIDR%/*}
cat << EOF > .env
GF_SECURITY_ADMIN_PASSWORD=$(cat /dev/urandom | base64 | fold -w 10 | head -n 1)
CONSUL_INITIAL_TOKEN=$(uuidgen)
VCP_VCC_PRIVATE_IPMASK=$CIDR
SERF_ADVERTISE=$IP
EOF

docker compose pull
docker compose up -d
