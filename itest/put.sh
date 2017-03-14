#!/bin/bash

set -e

test_dir=$(dirname $0)

source $test_dir/helpers.sh

# WARNING: These tests will CREATE and then DESTROY test orgs and spaces
timestamp=$(date +%s)
org=org-$timestamp
space=space-$timestamp
mysql_si=db-$timestamp
rabbitmq_si=rabbitmq-$timestamp
app_name=static-$timestamp

source=$(jq -n \
'{
  source: {
    api: "https://api.local.pcfdev.io",
    skip_cert_check: "true",
    username: "admin",
    password: "admin",
  }
}')

it_can_create_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  '{
    create_org: {
      org: $org
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_org_exists "$org"
}

it_can_create_a_space() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    create_space: {
      org: $org,
      space: $space
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

it_can_create_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

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

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$mysql_si"
}

it_can_create_a_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$rabbitmq_si" \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-rabbitmq",
      plan: "standard",
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$rabbitmq_si"
}

it_can_push_an_app_with_manifest() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  create_static_app "$app_name" "$working_dir"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    push: {
      org: $org,
      space: $space,
      manifest: "static-app/manifest.yml",
      current_app_name: $app_name
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  curl --output /dev/null --silent --head --fail http://$app_name.local.pcfdev.io/
}

it_can_delete_an_app_with_manifest() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    delete: {
      org: $org,
      space: $space,
      app_name: $app_name,
      delete_mapped_routes: "true"
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! curl --output /dev/null --silent --head --fail http://$app_name.local.pcfdev.io/
}

it_can_delete_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

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

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$mysql_si"
}

it_can_delete_a_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$rabbitmq_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$rabbitmq_si"
}

it_can_delete_a_space() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  --arg space $space \
  '{
    delete_space: {
      org: $org,
      space: $space
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_space_exists "$org" "$space"
}

it_can_delete_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org $org \
  '{
    delete_org: {
      org: $org
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_org_exists "$space"
}

run it_can_create_an_org
run it_can_create_a_space
run it_can_create_a_mysql_service
run it_can_create_a_rabbitmq_service
run it_can_push_an_app_with_manifest
run it_can_delete_an_app_with_manifest
run it_can_delete_a_rabbitmq_service
run it_can_delete_a_mysql_service
run it_can_delete_a_space
run it_can_delete_an_org
