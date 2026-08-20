#!/bin/bash
set -euo pipefail

cert_dir=${1:-cert}
retension_days=${2:-30}
mkdir -p "$cert_dir"
cd "$cert_dir"

tmpdir=$(mktemp -d)
cleanup() {
    echo 'Cleanup tmp'
    rm -rf "$tmpdir"
    echo 'Cleanup complete'
}
trap cleanup EXIT

cat <<EOF > "$tmpdir/ca.cnf"
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[ req_distinguished_name ]
CN = MyPrivateCA

[ v3_ca ]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

cat <<EOF > "$tmpdir/req.cnf"
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = occtr
DNS.3 = vault
IP.1 = 127.0.0.1
EOF

openssl req -x509 -nodes -days "$retension_days" -newkey rsa:2048 \
  -config "$tmpdir/ca.cnf" \
  -keyout occtr_ca.key \
  -out occtr_ca.crt \
  -subj "/CN=MyPrivateCA"

openssl req -nodes -newkey rsa:2048 \
  -keyout occtr.key \
  -out occtr.csr \
  -subj "/CN=localhost"

openssl x509 -req -days "$retension_days" \
  -in occtr.csr \
  -CA occtr_ca.crt \
  -CAkey occtr_ca.key \
  -CAcreateserial \
  -extfile "$tmpdir/req.cnf" \
  -extensions v3_req \
  -out occtr.crt

openssl verify -CAfile occtr_ca.crt occtr.crt
openssl x509 -in occtr.crt -text -noout | grep -A 1 "Subject Alternative Name"
