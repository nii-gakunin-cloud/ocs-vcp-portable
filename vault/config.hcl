storage "file" {
  path = "/bao/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/bao/cert/occtr.crt"
  tls_key_file = "/bao/cert/occtr.key"
}

## vcc_access_token から consul一時トークンを取得する場合のサンプル
#plugin_directory = "/opt/occ/var/vault/plugins"
#plugin_download_behavior = "fail"
#plugin_auto_download = true
#plugin_auto_register = true
## https://github.com/openbao/openbao-plugins/pkgs/container/openbao-plugin-secrets-consul
#plugin "secret" "consul" {
#  image       = "ghcr.io/openbao/openbao-plugin-secrets-consul"
#  version     = "v0.1.1"
#  binary_name = "openbao-plugin-secrets-consul"
#  sha256sum   = "0f8e436dfc543dd5e4756866bde3e20a93b69a0f5757d09d2fe1e41cd38f5ed7"
#}

# 10 years
max_lease_ttl = "87600h"
default_lease_ttl = "87600h"