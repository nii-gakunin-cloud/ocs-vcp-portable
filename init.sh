#!/bin/bash

CIDR=$(ip -o -4 addr show | grep -v ' lo' | awk '{print $4}' | head -n 1)
IP=${CIDR%/*}

if [ ! -e .env ]; then
    cat << EOF > .env
GF_SECURITY_ADMIN_PASSWORD=$(cat /dev/urandom | base64 | fold -w 10 | head -n 1)
CONSUL_INITIAL_TOKEN=$(uuidgen)
VCP_VCC_PRIVATE_IPMASK=$CIDR
SERF_ADVERTISE=$IP
BC_REGISTRY_HOST=$IP
EOF
fi

if [ ! -d cert ]; then
    sh ./tools/create_dummy_cert.sh
    chown root:1000 ./cert/occtr.key
    chmod 640 ./cert/occtr.key
fi

mkdir -p ./vault/data
chown 1000:1000 ./vault/data
# docker compose up -d --scale worker=3