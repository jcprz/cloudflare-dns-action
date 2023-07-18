#!/bin/bash
set -e

case "$ACTION" in
    check)
        response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$RECORD_TYPE&name=$RECORD_NAME" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json" | jq -r '.result[]?.name')

        if [ "$response" == "$RECORD_NAME" ]; then
            echo "DNS Record exists"
            exit 0
        else
            echo "DNS Record does not exist"
            if [ "$CREATE_IF_NOT_EXISTS" == "true" ]; then
                bash $0 create
            else
                exit 1
            fi
        fi
        ;;

    create)
        curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            --data \
                "{
                \"type\": \"$RECORD_TYPE\",
                \"name\": \"$RECORD_NAME\",
                \"content\": \"$RECORD_CONTENT\",
                \"ttl\":1,
                \"proxied\":false
                }"
        ;;

    delete)
        curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_NAME" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json"
        ;;
esac
