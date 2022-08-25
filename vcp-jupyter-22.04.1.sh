#!/bin/bash
#set -e

passwd=$1
subdir=jupyter

JUPYTER_TAG=20220408-dd4a

# release, portは必要な場合変える
release=22.04.1
port=8888

if [ "$passwd" = "" ]; then
    echo "Usage: $0 jupyter_login_password [port] [subdir]"
    echo "specify jupyter_login_password"
    exit 1
fi

if [ -n "$2" ]; then
    port=$2
fi

if [ -n "$3" ]; then
    subdir=$3
fi

echo port "$port"
echo subdir "$subdir"

#curl -fsSL https://s3-ap-northeast-1.amazonaws.com/vcp-jupyternotebook/$release/env > env
# s3上のenvでrelease (overwrite), JUPYTER_TAG を定義している
# envのリリースはvcpsdkでのリリース (例: 19.10.1 -> 19.10.0)
#. ./env

# vcpsdk and notebook tar ball
vcpsdk_file=https://s3-ap-northeast-1.amazonaws.com/vcp-jupyternotebook/${release}/jupyternotebook_vcpsdk-${release}.tgz
#image_name=harbor.vcloud.nii.ac.jp/vcpjupyter/cloudop-notebook:$JUPYTER_TAG
image_name=quay.io/ascade/vcpjupyter/cloudop-notebook:$JUPYTER_TAG

# container name
name=cloudop-notebook-$release-$subdir-$port

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

