#!/bin/sh

IP=$(hostname -I >/dev/null 2>&1 && hostname -I | awk '{print $1}' 2>/dev/null || hostname -i | awk '{print $1}')

exec /usr/local/bin/serf agent \
  -node=${SERF_NODE:-'portable_vcc'} \
  -bind=${SERF_BIND:-'0.0.0.0:7947'} \
  -discover=${SERF_DISCOVER:-'portable_vcc_cluster'} \
  -rpc-addr=${SERF_RPC_ADDR:-'0.0.0.0:7373'} \
  -advertise=${SERF_ADVERTISE:-$IP} $@