#!/bin/bash

VPN_CATALOG_FILE=$(dirname $0)/../config/vpn_catalog.yml

echo -n "Switch ID: "
read RESOURCE_ID
if [[ "$RESOURCE_ID" =~ ^[0-9]{8,}$ ]]; then
  sed -i.orig "s/000000000000/$RESOURCE_ID/" $VPN_CATALOG_FILE
  cat $VPN_CATALOG_FILE
else
  echo "ID format is invalid."
  exit 1
fi

