#!/bin/bash

cert_dir=${1:-cert}
retension_days=${2:-30}
mkdir -p "$cert_dir"
cd "$cert_dir"

cat <<EOF > req.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = JP
O = DummyOrg
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -x509 -nodes -days "$retension_days" -newkey rsa:2048 \
  -config req.cnf \
  -keyout key.pem \
  -out cert.pem

rm req.cnf

mv cert.pem occtr_cert.pem
mv key.pem occtr_key.pem