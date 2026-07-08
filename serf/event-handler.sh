#!/bin/sh

echo "[INFO][EHANDLER] Eventhandler called $SERF_EVENT"

TARGET_FILE="/etc/prometheus/targets.json"

if [ ! -s "$TARGET_FILE" ]; then
    echo '[]' > "$TARGET_FILE"
fi

while read -r node_name node_addr node_role tags; do

    if [ -z "$node_name" ] || [ -z "$node_addr" ]; then
        continue
    fi

    target_addr="${node_addr}:18083"
    target_addr_gpu="${node_addr}:9400"
    job_name="basecontainer"
    node_json_array="[$node_name]"

    case "$SERF_EVENT" in
        "member-join")
            echo "[INFO][EHANDLER] Node joined: $node_name ($target_addr)"

            if [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" --max-time 1 "http://$target_addr_gpu/metrics")" ]; then
                target_addr_gpu="${node_addr}:18083"
            fi
            
            if [ -s "$TARGET_FILE" ] && [ "$(jq '. | length' "$TARGET_FILE")" -gt 0 ]; then
                jq --arg target "$target_addr" \
                    'map(if .labels.job == "basecontainer" then .targets = (.targets + [$target] | unique) else . end)' \
                    "$TARGET_FILE" > "${TARGET_FILE}.tmp" && cat "${TARGET_FILE}.tmp" > "$TARGET_FILE" && rm "${TARGET_FILE}.tmp"
            else
                jq -n --arg target "$target_addr" \
                    '[{"targets": [$target], "labels": {"job": "basecontainer"}}]' \
                    > "${TARGET_FILE}.tmp" && cat "${TARGET_FILE}.tmp" > "$TARGET_FILE" && rm "${TARGET_FILE}.tmp"
            fi
            ;;

        "member-leave")
            echo "[INFO][EHANDLER] Node left: $node_name ($target_addr)"
            
            jq --arg target "$target_addr" \
                'map(if .labels.job == "basecontainer" then .targets = (.targets | del(.[] | select(. == $target))) else . end)' \
                "$TARGET_FILE" > "${TARGET_FILE}.tmp" && cat "${TARGET_FILE}.tmp" > "$TARGET_FILE" && rm "${TARGET_FILE}.tmp"
            ;;

        "member-fail")
            echo "[INFO][EHANDLER] Node failed (keeping in targets): $node_name ($target_addr)"
            NOTIFY_URL="https://localhost/vcp/v1/occtr/vcs/fail"
            curl --silent --show-error \
                --request POST \
                --header "Content-Type: application/json" \
                --data "$(jq -n \
                    --arg event "$SERF_EVENT" \
                    --argjson nodes "$node_json_array" \
                    '{"eventtype": $event, "tag": $nodes}')" \
                "$NOTIFY_URL" > /dev/null
            ;;

        *)
            ;;
    esac

done