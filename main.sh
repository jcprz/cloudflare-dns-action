#!/bin/bash
set -e

auth_token=$1
zone_id=$2
record_type=$3
record_name=$4
record_content=$5
action=$6
create_if_not_exists=$7
ttl=$8
comment=$9
proxied=${10}
delete_older_than=${11}
delete_regex_match=${12}
dry_run=${13}

# Transform the delete_older_than value to seconds
if [[ $delete_older_than == *s || $delete_older_than == *S ]]; then
  delete_older_than=${delete_older_than::-1}
elif [[ $delete_older_than == *m || $delete_older_than == *M ]]; then
  delete_older_than=$((${delete_older_than::-1} * 60))
elif [[ $delete_older_than == *h || $delete_older_than == *H ]]; then
  delete_older_than=$((${delete_older_than::-1} * 3600))
elif [[ $delete_older_than == *d || $delete_older_than == *D ]]; then
  delete_older_than=$((${delete_older_than::-1} * 86400))
else
  delete_older_than=$((${delete_older_than} * 60))  # Default to minutes
fi

# Check or validate DNS record
if [[ $action == "validate" ]]; then
  response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${record_type}&name=${record_name}" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$response" != "null" ]; then
    echo "DNS Record exists"
  else
    echo "DNS Record does not exist"
    if [[ $create_if_not_exists == "true" ]]; then
      action="create"
    else
      exit 1
    fi
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
  echo "Fetching DNS records"
  records=$(curl -s "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?per_page=100" \
    -H "Authorization: Bearer ${auth_token}" \
    -H "Content-Type: application/json" | \
    jq -r '.result[] | select(.name == "'"${record_name}"'") | select(.type == "'"${record_type}"'") | "\(.id) \(.created_on)"')

        # Print and backup records
  echo "$records" > backup.txt
  echo "Backed up records to backup.txt"

  if [[ "$dry_run" == "true" ]]; then
    echo "Dry run mode. These records would be deleted:"
    echo "$records"
    exit 0
  fi
  
  if [[ -z $delete_regex_match ]] || [[ $delete_regex_match == "*" ]]; then
    echo "Refusing to delete all records. Please provide a specific pattern to match."
    exit 1
  fi

  while read line; do
    id=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    type=$(echo "$line" | awk '{print $3}')
    content=$(echo "$line" | awk '{print $4}')
    created_on=$(echo "$line" | awk '{print $5"T"$6}')
  
    if [[ $type == $record_type ]] && [[ $name =~ $delete_regex_match ]]; then
      created_on=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo $created_on | cut -d. -f1)" "+%s")
      now=$(date +%s)
  
      if [[ -z $delete_older_than ]] || (( now - created_on > delete_older_than )); then
        echo "Deleting record $id"
      curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${id}" \
        -H "Authorization: Bearer ${auth_token}" \
        -H "Content-Type: application/json"
      fi
    fi
  done <<< "$records"
fi