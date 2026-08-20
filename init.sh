#!/bin/bash

CIDR=$(ip -o -4 addr show | grep -v ' lo' | awk '{print $4}' | head -n 1)
IP=${CIDR%/*}
CERT_DIR='./cert'

# install docker if not installed
if ! command -v docker >/dev/null 2>&1; then
    set -e
    apt-get update -y
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y

    # install docker
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    set +e
fi

if [ ! -e .env ]; then
    cat << EOF > .env
OCCTR_IMAGE=harbor.vcloud.nii.ac.jp/vcp/occtr:26.10.0
GF_SECURITY_ADMIN_PASSWORD=$(cat /dev/urandom | base64 | fold -w 10 | head -n 1)
CONSUL_INITIAL_TOKEN=$(uuidgen)
VCP_VCC_PRIVATE_IPMASK=$CIDR
SERF_ADVERTISE=$IP
BC_REGISTRY_HOST=$IP
EOF
fi

# Create cert
if [ ! -d "$CERT_DIR" ]; then
    bash tools/create_dummy_cert.sh "$CERT_DIR" 3600
fi
chown root:1000 "$CERT_DIR/occtr.key"
chmod 640 "$CERT_DIR/occtr.key"

mkdir -p ./vault/data
chown 1000:1000 ./vault/data
chmod 770 ./vault/data
# docker compose up -d --scale worker=3