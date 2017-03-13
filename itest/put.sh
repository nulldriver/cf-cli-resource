#!/bin/bash

set -e

test_dir=$(dirname $0)

source $test_dir/helpers.sh

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
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  '{
    create_org: {
      org: $org
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_org_exists "$org"
}

it_can_create_a_space() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    create_space: {
      org: $org,
      space: $space
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

it_can_create_a_mysql_service() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

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

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$mysql_si"
}

it_can_push_an_app_with_manifest() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  cp -R $test_dir/fixtures/static-app $src/.

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    push: {
      org: $org,
      space: $space,
      manifest: "static-app/manifest.yml",
      current_app_name: "static-app"
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '
  curl --output /dev/null --silent --head --fail http://static-app.local.pcfdev.io/
}

it_can_delete_a_mysql_service() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

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

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$mysql_si"
}

it_can_delete_a_space() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    delete_space: {
      org: $org,
      space: $space
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_space_exists "$org" "$space"
}

it_can_delete_an_org() {
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  '{
    delete_org: {
      org: $org
    }
  }')

  put_with_params $api $skip_cert_check "$username" "$password" "$params" "$src" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_org_exists "$space"
}

run it_can_create_an_org
run it_can_create_a_space
run it_can_create_a_mysql_service
run it_can_push_an_app_with_manifest
run it_can_delete_a_mysql_service
run it_can_delete_a_space
run it_can_delete_an_org
