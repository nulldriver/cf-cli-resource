#!/bin/bash

set -eu
set -o pipefail

test_dir=$(dirname $0)

source $test_dir/helpers.sh

# WARNING: These tests will CREATE and then DESTROY test orgs and spaces
testprefix=cfclitest
timestamp=$(date +%s)
cf_host="${CF_HOST:-local.pcfdev.io}"
cf_api="${CF_API:-https://api.$cf_host}"
cf_skip_cert_check=true
cf_username="${CF_USERNAME:-admin}"
cf_password="${CF_PASSWORD:-admin}"
org=$testprefix-org-$timestamp
space=$testprefix-space-$timestamp
username=$testprefix-user-$timestamp
password=$testprefix-pass-$timestamp
origin_username=$testprefix-originuser-$timestamp
origin=sso
cups_credentials_string_si=$testprefix-cups_credentials_string-$timestamp
cups_credentials_file_si=$testprefix-cups_credentials_file-$timestamp
cups_syslog_si=$testprefix-cups_syslog-$timestamp
cups_route_si=$testprefix-cups_route-$timestamp
mysql_si=$testprefix-db-$timestamp
rabbitmq_si=$testprefix-rabbitmq-$timestamp
service_registry_si=$testprefix-service_registry-$timestamp
config_server_si=$testprefix-config_server-$timestamp
circuit_breaker_dashboard_si=$testprefix-circuit_breaker_dashboard-$timestamp
app_name=$testprefix-app-$timestamp
broker_name=$testprefix-broker-$timestamp

# cf dev start -s all
source=$(jq -n \
--arg api "$cf_api" \
--arg skip_cert_check "$cf_skip_cert_check" \
--arg username "$cf_username" \
--arg password "$cf_password" \
--arg org "$org" \
--arg space "$space" \
'{
  source: {
    api: $api,
    skip_cert_check: "true",
    username: $username,
    password: $password,
    org: $org,
    space: $space,
    debug: false
  }
}')

it_can_create_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  '{
    command: "create-org",
    org: $org
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
  --arg org "$org" \
  --arg space "$space" \
  '{
    command: "create-space",
    org: $org,
    space: $space
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

it_can_create_a_user_with_password() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg username "$username" \
  --arg password "$password" \
  '{
    command: "create-user",
    org: $org,
    space: $space,
    username: $username,
    password: $password
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_exists "$username"
}

it_can_create_a_user_with_origin() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg username "$origin_username" \
  --arg origin "$origin" \
  '{
    command: "create-user",
    org: $org,
    space: $space,
    username: $username,
    origin: $origin
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_exists "$username"
}

it_can_create_users_from_file() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  mkdir -p $working_dir/input
  cp $test_dir/users.csv $working_dir/input

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    command: "create-users-from-file",
    org: $org,
    space: $space,
    file: "input/users.csv"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_exists "bulkloadtestuser1"
  cf_user_exists "bulkloadtestuser2"
  cf_user_exists "bulkloadtestuser3"
}

it_can_create_a_user_provided_service_with_credentials_string() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$cups_credentials_string_si" \
  --arg credentials '{"username":"admin","password":"pa55woRD"}' \
  '{
    command: "create-user-provided-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    credentials: $credentials
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_provided_service_exists "$cups_credentials_string_si"
}

it_can_create_a_user_provided_service_with_credentials_file() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  mkdir -p $working_dir/input

  echo \
  '{
    "username": "admin",
    "password": "pa55woRD"
  }' > $working_dir/input/credentials.json

  cat $working_dir/input/credentials.json

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$cups_credentials_file_si" \
  --arg credentials 'input/credentials.json' \
  '{
    command: "create-user-provided-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    credentials: $credentials
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_provided_service_exists "$cups_credentials_file_si"
}

it_can_create_a_user_provided_service_with_syslog() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$cups_syslog_si" \
  --arg syslog_drain_url "syslog://example.com" \
  '{
    command: "create-user-provided-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    syslog_drain_url: $syslog_drain_url
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_provided_service_exists "$cups_syslog_si"
}

it_can_create_a_user_provided_service_with_route() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$cups_route_si" \
  --arg route_service_url "https://example.com" \
  '{
    command: "create-user-provided-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    route_service_url: $route_service_url
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_user_provided_service_exists "$cups_route_si"
}

it_can_create_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: "p-mysql",
    plan: "512mb",
    service_instance: $service_instance
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
    command: "create-service",
    org: $org,
    space: $space,
    service: "p-rabbitmq",
    plan: "standard",
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$rabbitmq_si"
}

it_can_create_a_service_registry() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_registry_si" \
  --arg configuration '{"count": 1}' \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: "p-service-registry",
    plan: "standard",
    service_instance: $service_instance,
    configuration: $configuration,
    wait_for_service: true
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$service_registry_si"
}

it_can_create_a_config_server() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$config_server_si" \
  --arg configuration '{"count": 1, "git": {"uri": "https://github.com/patrickcrocker/cf-SpringBootTrader-config.git"}}' \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: "p-config-server",
    plan: "standard",
    service_instance: $service_instance,
    configuration: $configuration,
    wait_for_service: true
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$config_server_si"
}

it_can_create_a_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  --arg configuration '{"count": 1}' \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: "p-circuit-breaker-dashboard",
    plan: "standard",
    service_instance: $service_instance,
    configuration: $configuration
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_wait_for_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  '{
    command: "wait-for-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_push_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  create_static_app "$app_name" "$working_dir"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "push",
    org: $org,
    space: $space,
    app_name: $app_name,
    hostname: $app_name,
    path: "static-app/content",
    manifest: "static-app/manifest.yml",
    no_start: "true"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_stopped "$app_name"
}

it_can_start_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "start",
    org: $org,
    space: $space,
    app_name: $app_name,
    staging_timeout: 15,
    startup_timeout: 5
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_started "$app_name"
}

it_can_zero_downtime_push() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  create_static_app "$app_name" "$working_dir"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "zero-downtime-push",
    manifest: "static-app/manifest.yml",
    current_app_name: $app_name,
    environment_variables: {
      key: "value",
      key2: "value2"
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_started "$app_name"
}

it_can_create_a_service_broker() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  if [ ! -d "$working_dir/broker" ]; then
    cf_target "$org" "$space"
    git clone https://github.com/mattmcneeney/overview-broker "$working_dir/broker"
    # pin to a specific commit for build reproducibility
    git -C "$working_dir/broker" reset --hard dddec578676b8dcbe06158e3ac0b34edc6f5de6e
    # pin to a specific buildpack for build reproducibility
    cf push "$broker_name" -p "$working_dir/broker" -b "https://github.com/cloudfoundry/nodejs-buildpack#v1.6.11"
  fi

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg broker_name "$broker_name" \
    --arg username admin \
    --arg password password \
    --arg url "https://$broker_name.$cf_host" \
    '{
      command: "create-service-broker",
      org: $org,
      space: $space,
      broker_name: $broker_name,
      username: $username,
      password: $password,
      url: $url
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_broker_exists "$broker_name"
}

it_can_enable_service_access() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local plan="simple"
  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg broker_name "$broker_name" \
    --arg enable_to_org "$org" \
    --arg plan "$plan" \
    '{
      command: "enable-service-access",
      org: $org,
      space: $space,
      broker_name: $broker_name,
      enable_to_org: $enable_to_org,
      plan: $plan
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_marketplace_service_available "$broker_name" "$plan"
}

it_can_delete_a_service_broker() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg broker_name "$broker_name" \
    '{
      command: "delete-service-broker",
      org: $org,
      space: $space,
      broker_name: $broker_name
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_broker_exists "$broker_name"
}

it_can_bind_user_provided_service_with_credentials_string() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance="$cups_credentials_string_si"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_user_provided_service_with_credentials_file() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance="$cups_credentials_file_si"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_user_provided_service_with_syslog() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance="$cups_syslog_si"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_user_provided_service_with_route() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance="$cups_route_si"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$mysql_si

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$rabbitmq_si

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "bind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_delete_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "delete",
    org: $org,
    space: $space,
    app_name: $app_name,
    delete_mapped_routes: "true"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_app_exists "$app_name"
}

it_can_delete_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
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
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$rabbitmq_si"
}

it_can_delete_a_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_delete_a_config_server() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$config_server_si" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$config_server_si"
}

it_can_delete_a_service_registry() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_registry_si" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$service_registry_si"
}

it_can_delete_a_user_with_password() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg username "$username" \
  '{
    command: "delete-user",
    org: $org,
    space: $space,
    username: $username
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_user_exists "$username"
}

it_can_delete_a_user_with_origin() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg username "$origin_username" \
  '{
    command: "delete-user",
    org: $org,
    space: $space,
    username: $username
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_user_exists "$origin_username"
}

it_can_delete_a_space() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    command: "delete-space",
    org: $org,
    space: $space
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
  --arg org "$org" \
  '{
    command: "delete-org",
    org: $org
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_org_exists "$org"
}

it_can_use_commands_syntax() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg service_instance "$mysql_si" \
  '{
    commands: [
      {
        command: "create-org",
      },
      {
        command: "create-space",
      },
      {
        command: "create-service",
        service: "p-mysql",
        plan: "512mb",
        service_instance: $service_instance
      },
      {
        command: "create-service",
        service: "p-mysql",
        plan: "512mb",
        service_instance: "si2"
      }
    ]
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

cleanup_failed_tests() {
  cf_login "$cf_api" "$cf_username" "$cf_password" "$cf_skip_cert_check"
  orgs=$(cf orgs | grep "$testprefix-org" || true)
  for org in $orgs; do
    cf_delete_org "$org"
  done
  cf_delete_user "bulkloadtestuser1"
  cf_delete_user "bulkloadtestuser2"
  cf_delete_user "bulkloadtestuser3"
}

run cleanup_failed_tests
run it_can_create_an_org
run it_can_create_a_space
run it_can_create_a_user_with_password
run it_can_create_a_user_with_origin
run it_can_create_a_service_broker
# run again to prove that it won't error out if it already exists
run it_can_create_a_service_broker
run it_can_enable_service_access
run it_can_delete_a_service_broker
run it_can_create_users_from_file
run it_can_create_a_user_provided_service_with_credentials_string
# run again to prove that it won't error out if it already exists
run it_can_create_a_user_provided_service_with_credentials_string
run it_can_create_a_user_provided_service_with_credentials_file
run it_can_create_a_user_provided_service_with_syslog
run it_can_create_a_user_provided_service_with_route
run it_can_create_a_mysql_service
run it_can_create_a_rabbitmq_service
run it_can_create_a_service_registry
run it_can_create_a_config_server
run it_can_create_a_circuit_breaker_dashboard
# run again to prove that it won't error out if it already exists
run it_can_create_a_circuit_breaker_dashboard
run it_can_wait_for_circuit_breaker_dashboard
run it_can_push_an_app
run it_can_bind_user_provided_service_with_credentials_string
run it_can_bind_user_provided_service_with_credentials_file
run it_can_bind_user_provided_service_with_syslog
run it_can_bind_user_provided_service_with_route
run it_can_bind_mysql_service
run it_can_bind_rabbitmq_service
run it_can_start_an_app
run it_can_zero_downtime_push
run it_can_delete_an_app
run it_can_delete_a_circuit_breaker_dashboard
run it_can_delete_a_config_server
run it_can_delete_a_service_registry
run it_can_delete_a_rabbitmq_service
run it_can_delete_a_mysql_service
run it_can_delete_a_user_with_origin
run it_can_delete_a_user_with_password
run it_can_delete_a_space
run it_can_delete_an_org
run it_can_use_commands_syntax
run it_can_delete_an_org
