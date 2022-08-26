#!/bin/bash -x

cd $(dirname $0)

sudo docker-compose down
sudo git clean -df
sudo docker kill cloudop-notebook-22.04.1-jupyter-8888
sudo docker rm cloudop-notebook-22.04.1-jupyter-8888

