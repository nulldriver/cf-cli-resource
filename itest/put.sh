#!/bin/bash

set -eu
set -o pipefail

test_dir=$(dirname $0)

source $test_dir/helpers.sh

# Defaults for PCF Dev (override by exporting your own vars before running this script)
: "${CF_SYSTEM_DOMAIN:=local.pcfdev.io}"
: "${CF_APPS_DOMAIN:=local.pcfdev.io}"
: "${CF_SKIP_CERT_CHECK:=true}"
: "${CF_USERNAME:=admin}"
: "${CF_PASSWORD:=admin}"
: "${SYNC_SERVICE:=p-mysql}"
: "${SYNC_PLAN:=512mb}"
: "${SYNC_CONFIGURATION:=}"
: "${ASYNC_SERVICE:=p-service-registry}"
: "${ASYNC_PLAN:=standard}"
: "${ASYNC_CONFIGURATION:='{\"count\": 1}'}"

# WARNING: These tests will CREATE and then DESTROY test orgs and spaces
testprefix=cfclitest
timestamp=$(date +%s)

cf_api="https://api.$CF_SYSTEM_DOMAIN"
cf_apps_domain=$CF_APPS_DOMAIN
cf_skip_cert_check=$CF_SKIP_CERT_CHECK
cf_username=$CF_USERNAME
cf_password=$CF_PASSWORD
cf_color=true
cf_dial_timeout=5
cf_trace=false

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

sync_service=$SYNC_SERVICE
sync_plan=$SYNC_PLAN
sync_service_instance=$testprefix-sync_service-$timestamp
sync_configuration=$SYNC_CONFIGURATION

async_service=$ASYNC_SERVICE
async_plan=$ASYNC_PLAN
async_service_instance=$testprefix-async_service-$timestamp
async_configuration=$ASYNC_CONFIGURATION

app_name=$testprefix-app-$timestamp
broker_name=$testprefix-broker

# cf dev start -s all
source=$(jq -n \
--arg api "$cf_api" \
--arg skip_cert_check "$cf_skip_cert_check" \
--arg username "$cf_username" \
--arg password "$cf_password" \
--arg org "$org" \
--arg space "$space" \
--arg cf_color "$cf_color" \
--arg cf_dial_timeout "$cf_dial_timeout" \
--arg cf_trace "$cf_trace" \
'{
  source: {
    api: $api,
    skip_cert_check: "true",
    username: $username,
    password: $password,
    org: $org,
    space: $space,
    debug: false,
    cf_color: $cf_color,
    cf_dial_timeout: $cf_dial_timeout,
    cf_trace: $cf_trace
  }
}')

it_can_create_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  '{
    command: "create-org",
    org: $org,
    cf_trace: "true"
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
    space: $space,
    cf_trace: "true"
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
  cat>$working_dir/input/users.csv <<EOF
Username,Password,Org,Space,OrgManager,BillingManager,OrgAuditor,SpaceManager,SpaceDeveloper,SpaceAuditor
bulkloadtestuser1,wasabi,$org,$space,x,x,x,x,x,x
bulkloadtestuser2,wasabi,$org,$space,,x,x,,x,x
bulkloadtestuser3,ldap,$org,$space,,,x,,,x
EOF

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

it_can_create_a_synchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service "$sync_service" \
  --arg plan "$sync_plan" \
  --arg service_instance "$sync_service_instance" \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: $service,
    plan: $plan,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$sync_service_instance"
}

it_can_create_an_asynchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service "$async_service" \
  --arg plan "$async_plan" \
  --arg service_instance "$async_service_instance" \
  --arg configuration '{"count": 1}' \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: $service,
    plan: $plan,
    service_instance: $service_instance,
    configuration: $configuration,
    wait_for_service: true
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$async_service_instance"
}

it_can_wait_for_asynchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$async_service_instance" \
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

  cf_service_exists "$async_service_instance"
}

it_can_push_an_app_no_start() {
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
    --arg service_broker "$broker_name" \
    --arg username admin \
    --arg password password \
    --arg url "https://$broker_name.$cf_apps_domain" \
    '{
      command: "create-service-broker",
      org: $org,
      space: $space,
      service_broker: $service_broker,
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
    --arg service_broker "$broker_name" \
    --arg access_org "$org" \
    --arg plan "$plan" \
    '{
      command: "enable-service-access",
      org: $org,
      space: $space,
      service_broker: $service_broker,
      access_org: $access_org,
      plan: $plan
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_marketplace_service_available "$broker_name" "$plan"
}

it_can_disable_service_access() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local plan="simple"
  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg service_broker "$broker_name" \
    --arg access_org "$org" \
    --arg plan "$plan" \
    '{
      command: "disable-service-access",
      org: $org,
      space: $space,
      service_broker: $service_broker,
      access_org: $access_org,
      plan: $plan
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_is_marketplace_service_available "$broker_name" "$plan"
}

it_can_delete_a_service_broker() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg service_broker "$broker_name" \
    '{
      command: "delete-service-broker",
      org: $org,
      space: $space,
      service_broker: $service_broker
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

it_can_bind_a_synchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$sync_service_instance

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

it_can_bind_an_asynchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$async_service_instance

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

it_can_delete_a_synchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$sync_service_instance

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_instance" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    wait_for_service: true
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$service_instance"
}

it_can_delete_an_asynchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$async_service_instance

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_instance" \
  '{
    command: "delete-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    wait_for_service: true
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$service_instance"
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

# This test showcases the multi-command syntax
it_can_delete_a_space_and_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    commands: [
      {
        command: "delete-space",
        org: $org,
        space: $space
      },
      {
        command: "delete-org",
        org: $org
      }
    ]
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_space_exists "$org" "$space"
  ! cf_org_exists "$org"
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
run it_can_create_users_from_file

run it_can_create_a_service_broker
# run again to prove that it won't error out if it already exists
run it_can_create_a_service_broker
run it_can_enable_service_access
run it_can_disable_service_access
run it_can_delete_a_service_broker

run it_can_create_a_user_provided_service_with_credentials_string
# run again to prove that it won't error out if it already exists
run it_can_create_a_user_provided_service_with_credentials_string
run it_can_create_a_user_provided_service_with_credentials_file
run it_can_create_a_user_provided_service_with_syslog
run it_can_create_a_user_provided_service_with_route

run it_can_push_an_app_no_start

run it_can_bind_user_provided_service_with_credentials_string
run it_can_bind_user_provided_service_with_credentials_file
run it_can_bind_user_provided_service_with_syslog
run it_can_bind_user_provided_service_with_route

run it_can_create_a_synchronous_service
run it_can_bind_a_synchronous_service

run it_can_create_an_asynchronous_service
run it_can_bind_an_asynchronous_service

run it_can_start_an_app
run it_can_zero_downtime_push

run it_can_delete_an_app

run it_can_delete_a_synchronous_service
run it_can_delete_an_asynchronous_service

run it_can_delete_a_user_with_origin
run it_can_delete_a_user_with_password

run it_can_delete_a_space_and_org
