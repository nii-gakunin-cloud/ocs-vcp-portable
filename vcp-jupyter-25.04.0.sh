#!/bin/bash
#set -e
passwd=$1

if [ "$passwd" = "" ]; then
    echo "Usage: $0 jupyter_login_password [port] [subdir]"
    echo "specify jupyter_login_password"
    exit 1
fi

# 以下は必要な場合変える
port=${2:-8888}
subdir=${3:-jupyter}
vcpsdk_release=${4:-23.04.0}
jupyter_release=${5:-20250401-ssl-cc}

echo port "$port"
echo subdir "$subdir"
echo vcpsdk_release "$vcpsdk_release"
echo jupyter_release "$jupyter_release"

# vcpsdk and notebook tar ball
vcpsdk_file=https://s3-ap-northeast-1.amazonaws.com/vcp-jupyternotebook/${vcpsdk_release}/jupyternotebook_vcpsdk-${vcpsdk_release}.tgz
image_name=harbor.vcloud.nii.ac.jp/vcpjupyter/cloudop-notebook:$jupyter_release

# container name
name=cloudop-notebook-$vcpsdk_release-$subdir-$port

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

# TODO: exit if docker run is not required
# run docker container
docker run -d --network host \
       --name "$name" \
       -e REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
       -e "JUPYTERHUB_SERVICE_PREFIX=/$subdir/"  \
       -e "PASSWORD=$passwd" -e TZ=JST-9 -e "SUBDIR=$subdir" \
       --restart=always "$image_name"

# extract vcpsdk to $HOME/vcp
docker exec --user jovyan "$name" \
    /bin/bash -c \
    "curl -fsSL $vcpsdk_file | ( cd \$HOME && mkdir -p vcp && cd vcp && tar xfz - )"

# copy vcpsdk to $HOME
docker exec --user jovyan "$name" \
    /bin/bash -c \
     "(cd \$HOME/vcp && cp -r vcpsdk \$HOME)"

# copy vcpsdk setup notebook and README.md to /notebooks/notebook
docker exec --user jovyan "$name" \
     /bin/bash -c \
     "(cd \$HOME/vcp && cp -r README.md vcpsdk/vcpsdk/SETUP.ipynb /notebooks/notebook)"

