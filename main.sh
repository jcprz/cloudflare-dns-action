#!/bin/bash
set -e

auth_token=$1
zone_id=$2
record_type=$3
record_name=$4
record_content=$5
action=$6
ttl=$7
comment=$8
proxied=$9

# Validate DNS record
if [[ $action == "validate" ]]; then
  response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${record_type}&name=${record_name}" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$response" != "null" ]; then
    echo "DNS Record exists"
  else
    echo "DNS Record does not exist"
    exit 1
  fi
fi

# Create DNS record
if [[ $action == "create" ]]; then
  echo "Creating DNS record"
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
    -H "Authorization: Bearer ${auth_token}" \
    -H "Content-Type: application/json" \
    --data \
      '{
        "type": "'"$record_type"'",
        "name": "'"$record_name"'",
        "content": "'"$record_content"'",
        "ttl": '"$ttl"',
        "proxied": '"$proxied"',
        "comment": "'"$comment"'"
      }'
fi

# Update DNS record
if [[ $action == "update" ]]; then
  echo "Updating DNS record"
  record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${record_type}&name=${record_name}" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "Content-Type: application/json" | jq -r '.result[0].id')
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
    -H "Authorization: Bearer ${auth_token}" \
    -H "Content-Type: application/json" \
    --data \
      '{
        "type": "'"$record_type"'",
        "name": "'"$record_name"'",
        "content": "'"$record_content"'",
        "ttl": '"$ttl"',
        "proxied": '"$proxied"',
        "comment": "'"$comment"'"
      }'
fi

# Delete DNS record
if [[ $action == "delete" ]]; then
  echo "Deleting DNS record"
  record_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${record_type}&name=${record_name}" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "Content-Type: application/json" | jq -r '.result[0].id')
  
  if [ "$record_id" != "null" ]; then
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "Content-Type: application/json"
  else
    echo "DNS Record does not exist, nothing to delete"
  fi
fi