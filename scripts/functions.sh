#!/bin/bash

check_command_availability() {
    if ! command -v "$1" &> /dev/null
    then
        echo "$1 could not be found, consider installing it"
        exit 1
    fi
}

check_variable() {
    if [ -z "${!1}" ]
    then
        echo "Variable '$1' is empty or not set"
        exit 1
    fi
}

update_dns_record() {
    local type="$1"
    local ip_address="$2"
    
    local records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$type&name=$DOMAIN" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json")

    existing_ip=$(echo $records | jq -r '.result[0]?.content')

    if [ "$existing_ip" == "$ip_address" ]; then
        echo "No action needed for $type record. IP is already set to $ip_address."
    else
        local payload="{\"content\":\"$ip_address\",\"type\":\"$type\",\"name\":\"$DOMAIN\",\"proxied\":true,\"ttl\":3600}"
        local record_id=$(get_dns_record_id $type)

        local method="PUT"
        local url="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id"

        if [ !$record_id ]; then
            method="POST" 
            url="https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"
        fi

        local result=$(curl -s -X $method $url \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            --data ""$payload"" | jq -r '.success')

        if [ $result ]; then
            echo "Updated $type record. IP set to $ip_address"
        else
            echo "Failed to set $type record with $ip_address"
        fi

    fi

    # Delete other records
    echo "$records" | jq -c '.result[1:][]' | while read -r record; do
        record_id=$(echo "$record" | jq -r '.id')

        local result=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json")

        if [ $result ]; then
            echo "Deleted unnecessary $type record"
        else
            echo "Failed to delete unnecessary $type record with record_id $record_id"
        fi    
    done
}

get_dns_record_id() {
    local type="$1"

    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$type&name=$DOMAIN" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        | jq -r '.result[0]?.id'
}
