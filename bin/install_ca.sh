#! /bin/bash
#　前提: このスクリプトからの相対パスで../cert/ca.pem にインストールする証明書が有ると仮定する
# set -e

cd $(dirname $(realpath $0))

if [ ! -d ../cert ]; then
    echo cannot find ../cert dir
    exit 1
fi

output=$(grep centos /etc/os-release) || result=$?
if [ "$result" = "0" ]; then
    # centos
    set -e
    cp ../cert/ca.pem /etc/pki/ca-trust/source/anchors/vcp_ca.crt
    update-ca-trust extract
    exit
fi

if [ -f /etc/alpine-release ] || [ -f /etc/lsb-release ]; then
# debian (jupyter) | alpine
    cp ../cert/ca.pem /usr/local/share/ca-certificates/vcp_ca.crt
    update-ca-certificates
    exit
fi

echo unknown os
exit 1
