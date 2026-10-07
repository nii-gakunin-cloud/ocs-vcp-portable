# Allow tokens to look up their own properties
path "auth/token/lookup-self" {
    capabilities = ["read"]
}

# Deny tokens to renew themselves
path "auth/token/renew-self" {
    capabilities = ["deny"]
}

# Deny tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["deny"]
}

# Deny a token to look up its own capabilities on a path
path "sys/capabilities-self" {
    capabilities = ["deny"]
}

# Deny a token to renew a lease via lease_id in the request body; old path for
# old clients, new path for newer
path "sys/renew" {
    capabilities = ["deny"]
}
path "sys/leases/renew" {
    capabilities = ["deny"]
}

# Allow looking up lease properties. This requires knowing the lease ID ahead
# of time and does not divulge any sensitive information.
path "sys/leases/lookup" {
    capabilities = ["read"]
}

# Allow a token to manage its own cubbyhole
path "cubbyhole/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow a token to manage secret
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow a token to wrap arbitrary values in a response-wrapping token
path "sys/wrapping/wrap" {
    capabilities = ["deny"]
}

# Allow a token to look up the creation time and TTL of a given
# response-wrapping token
path "sys/wrapping/lookup" {
    capabilities = ["deny"]
}

# Allow a token to unwrap a response-wrapping token. This is a convenience to
# avoid client token swapping since this is also part of the response wrapping
# policy.
path "sys/wrapping/unwrap" {
    capabilities = ["deny"]
}

# vcc_access_token から consul一時トークンを取得する場合に必要
#path "consul/creds/vcc-access-token-role" {
#  capabilities = ["read"]
#}