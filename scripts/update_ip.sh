#!/bin/bash

if [ ! -e "settings.sh" ]; then
    echo "File settings.sh does not exist, create it"
    echo "Check sample settings.sh.sample"
    exit 1
fi

source settings.sh
source functions.sh

check_variable "API_KEY"
check_variable "ZONE_ID"
check_variable "DOMAIN"

check_command_availability "dig"
check_command_availability "jq"

IPv4=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')
IPv6=$(dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')

update_dns_record "A" "$IPv4"
update_dns_record "AAAA" "$IPv6"