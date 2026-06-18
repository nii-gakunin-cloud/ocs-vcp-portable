#!/bin/bash
set -e

# 以下は必要な場合変える
port=${1:-8888}
subdir=${2:-jupyter}

echo port "$port"
echo subdir "$subdir"

# container name
name=cloudop-notebook-$subdir-$port

# check exist container
result=$(docker ps -a | grep "$name" || true)

if [ "$result" != "" ]; then
    echo "already exist container name $name"
    echo "backup files and remove container"
    exit 1
fi

# JupyterNotebook container image
# pull docker container image
docker pull "$image_name"

docker run -d --network host \
       --name "$name" \
       -e REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
       -e "JUPYTERHUB_SERVICE_PREFIX=/$subdir/"  \
       -e TZ=JST-9 -e "SUBDIR=$subdir" \
       -e "JUPYTER_PORT=$port" \
       --restart=always "$image_name"
