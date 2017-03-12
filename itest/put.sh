#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

# WARNING: These tests will CREATE and then DESTROY test orgs and spaces
api=https://api.local.pcfdev.io
skip_cert_check=true
username=admin
password=admin
timestamp=$(date +%s)
org=org-$timestamp
space=space-$timestamp
mysql_si=db-$timestamp

it_can_create_an_org() {
  local params=$(jq -n \
  --arg org $org \
  '{
    create_org: {
      org: $org
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_org_exists "$org"
}

it_can_create_a_space() {
  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    create_space: {
      org: $org,
      space: $space
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$space"
}

it_can_create_a_mysql_service() {
  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-mysql",
      plan: "512mb",
      service_instance: $service_instance
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$mysql_si"
}

it_can_delete_a_mysql_service() {
  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$mysql_si"
}

it_can_delete_a_space() {
  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    delete_space: {
      org: $org,
      space: $space
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_space_exists "$space"
}

it_can_delete_an_org() {
  local params=$(jq -n \
  --arg org $org \
  '{
    delete_org: {
      org: $org
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_org_exists "$space"
}

run it_can_create_an_org
run it_can_create_a_space
run it_can_create_a_mysql_service
run it_can_delete_a_mysql_service
run it_can_delete_a_space
run it_can_delete_an_org
