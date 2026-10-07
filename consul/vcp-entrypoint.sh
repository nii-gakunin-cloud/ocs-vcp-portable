#!/bin/sh

if [ -z "$CONSUL_INITIAL_TOKEN" ]; then
  echo "CONSUL_INITIAL_TOKEN is not specified"
  exit 1
fi

TEMPLATE_FILE="/consul/config/default.json.template"
OUTPUT_FILE="/consul/config/default.json"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Not found $TEMPLATE_FILE" >&2
    exit 1
fi

jq --arg token "$CONSUL_INITIAL_TOKEN" '.acl.tokens.initial_management = $token' "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Success: Created $OUTPUT_FILE"

docker-entrypoint.sh $@