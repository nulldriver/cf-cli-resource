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
: "${ASYNC_CONFIGURATION:=}"

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

org="$testprefix Org $timestamp"
space="$testprefix Space $timestamp"

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

domain=$testprefix-domain-$timestamp.com

app_name=$testprefix-app-$timestamp
broker_name=$testprefix-broker
broker_space_scoped_name=$testprefix-space-scoped-broker

users_csv=$(cat <<EOF
Username,Password,Org,Space,OrgManager,BillingManager,OrgAuditor,SpaceManager,SpaceDeveloper,SpaceAuditor
$testprefix-bulkload-user1,wasabi,$org,$space,x,x,x,x,x,x
$testprefix-bulkload-user2,wasabi,$org,$space,,x,x,,x,x
$testprefix-bulkload-user3,ldap,$org,$space,,,x,,,x
EOF
)

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
  echo "$users_csv" > $working_dir/input/users.csv

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

  cf_user_exists "$testprefix-bulkload-user1"
  cf_user_exists "$testprefix-bulkload-user2"
  cf_user_exists "$testprefix-bulkload-user3"
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

  cf_service_exists "$cups_credentials_string_si"
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

  cf_service_exists "$cups_credentials_file_si"
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

  cf_service_exists "$cups_syslog_si"
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

  cf_service_exists "$cups_route_si"
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
    service_instance: $service_instance,
    wait_for_service: true
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
  --arg configuration "$async_configuration" \
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

it_can_enable_service_instance_sharing() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "enable-feature-flag",
    feature_name: "service_instance_sharing"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_feature_flag_enabled "service_instance_sharing"
}

it_can_disable_service_instance_sharing() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "disable-feature-flag",
    feature_name: "service_instance_sharing"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_feature_flag_disabled "service_instance_sharing"
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

it_can_restart_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "restart",
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

it_can_restage_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    command: "restage",
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
    org: $org,
    space: $space,
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

it_can_run_a_task_with_disk_quota() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg task_command "echo run-task-with-disk_quota-test" \
  --arg disk_quota "756M" \
  '{
    command: "run-task",
    org: $org,
    space: $space,
    app_name: $app_name,
    task_command: $task_command,
    disk_quota: $disk_quota
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_was_task_run "$app_name" "run-task-with-disk_quota-test"
}

it_can_run_a_task_with_memory() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg task_command "echo run-task-with-memory-test" \
  --arg memory "512M" \
  '{
    command: "run-task",
    org: $org,
    space: $space,
    app_name: $app_name,
    task_command: $task_command,
    memory: $memory
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_was_task_run "$app_name" "run-task-with-memory-test"
}

it_can_run_a_task_with_name() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg task_command "echo run-task-with-name-test" \
  --arg task_name "run-task-with-name-test" \
  '{
    command: "run-task",
    org: $org,
    space: $space,
    app_name: $app_name,
    task_command: $task_command,
    task_name: $task_name
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_was_task_run "$app_name" "run-task-with-name-test"
}

it_can_run_a_task() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg task_command "echo run-task-test-all" \
  --arg task_name "run-task-test-all" \
  --arg memory "512M" \
  --arg disk_quota "756M" \
  '{
    command: "run-task",
    org: $org,
    space: $space,
    app_name: $app_name,
    task_command: $task_command,
    task_name: $task_name,
    memory: $memory,
    disk_quota: $disk_quota
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_was_task_run "$app_name" "run-task-test-all"
}

it_can_scale_an_app_instances() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg instances "2" \
  '{
    command: "scale",
    org: $org,
    space: $space,
    app_name: $app_name,
    instances: $instances
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert_equals 2 "$(cf_get_app_instances "$app_name")"
}

it_can_scale_an_app_disk_quota() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg disk_quota "512M" \
  '{
    command: "scale",
    org: $org,
    space: $space,
    app_name: $app_name,
    disk_quota: $disk_quota
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert_equals 512 "$(cf_get_app_disk_quota "$app_name")"
}

it_can_scale_an_app_memory() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg memory "512M" \
  '{
    command: "scale",
    org: $org,
    space: $space,
    app_name: $app_name,
    memory: $memory
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert_equals 512 "$(cf_get_app_memory "$app_name")"
}

it_can_scale_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg instances "1" \
  --arg disk_quota "1G" \
  --arg memory "1G" \
  '{
    command: "scale",
    org: $org,
    space: $space,
    app_name: $app_name,
    instances: $instances,
    disk_quota: $disk_quota,
    memory: $memory
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert_equals 1 "$(cf_get_app_instances "$app_name")"
  assert_equals 1024 "$(cf_get_app_disk_quota "$app_name")"
  assert_equals 1024 "$(cf_get_app_memory "$app_name")"
}

it_can_create_a_domain() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg domain "$domain" \
  '{
    command: "create-domain",
    org: $org,
    domain: $domain
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_has_private_domain "$org" "$domain"
}

it_can_delete_a_domain() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg domain "$domain" \
  '{
    command: "delete-domain",
    org: $org,
    domain: $domain
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_has_private_domain "$org" "$domain"
}

it_can_map_a_route() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  '{
    command: "map-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was mapped
}

it_can_map_a_route_with_hostname() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  --arg hostname "$app_name" \
  '{
    command: "map-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain,
    hostname: $hostname
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was mapped
}

it_can_map_a_route_with_hostname_and_path() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  --arg hostname "$app_name" \
  --arg path "foo" \
  '{
    command: "map-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain,
    hostname: $hostname,
    path: $path
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was mapped
}

it_can_unmap_a_route_with_hostname_and_path() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  --arg hostname "$app_name" \
  --arg path "foo" \
  '{
    command: "unmap-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain,
    hostname: $hostname,
    path: $path
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was unmapped
}

it_can_unmap_a_route_with_hostname() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  --arg hostname "$app_name" \
  '{
    command: "unmap-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain,
    hostname: $hostname
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was unmapped
}

it_can_unmap_a_route() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg domain "$domain" \
  '{
    command: "unmap-route",
    org: $org,
    space: $space,
    app_name: $app_name,
    domain: $domain
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '
  # TODO: check that the route was unmapped
}

it_can_create_a_service_broker_space_scoped() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local commit=dddec578676b8dcbe06158e3ac0b34edc6f5de6e

  # if tests are running in concourse, the overview-broker.zip is provided
  # by the pipeline.  Otherwise, if we are running locally, we'll need to
  # download it.
  local broker_dir=$working_dir/broker
  if [ -d "/opt/service-broker" ]; then
    broker_dir=/opt/service-broker
  else
    mkdir -p $broker_dir
  fi

  if [ ! -f "$broker_dir/overview-broker.zip" ]; then
    wget https://github.com/mattmcneeney/overview-broker/archive/$commit.zip -O $broker_dir/overview-broker.zip
  fi

  if [ ! -d "$broker_dir/overview-broker-$commit" ]; then
    unzip $broker_dir/overview-broker.zip -d $broker_dir
  fi

  cf_login "$cf_api" "$cf_username" "$cf_password" "$cf_skip_cert_check"
  cf_target "$org" "$space"
  cf push "${broker_space_scoped_name}" -p "$broker_dir/overview-broker-$commit" #-b "https://github.com/cloudfoundry/nodejs-buildpack#v1.6.11"
  cf logout

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg service_broker "${broker_space_scoped_name}" \
    --arg username admin \
    --arg password password \
    --arg url "https://${broker_space_scoped_name}.$cf_apps_domain" \
    '{
      command: "create-service-broker",
      org: $org,
      space: $space,
      service_broker: $service_broker,
      username: $username,
      password: $password,
      url: $url,
      space_scoped: true
    }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_broker_exists "${broker_space_scoped_name}"
}

it_can_create_a_service_broker() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local commit=dddec578676b8dcbe06158e3ac0b34edc6f5de6e

  # if tests are running in concourse, the overview-broker.zip is provided
  # by the pipeline.  Otherwise, if we are running locally, we'll need to
  # download it.
  local broker_dir=$working_dir/broker
  if [ -d "/opt/service-broker" ]; then
    broker_dir=/opt/service-broker
  else
    mkdir -p $broker_dir
  fi

  if [ ! -f "$broker_dir/overview-broker.zip" ]; then
    wget https://github.com/mattmcneeney/overview-broker/archive/$commit.zip -O $broker_dir/overview-broker.zip
  fi

  if [ ! -d "$broker_dir/overview-broker-$commit" ]; then
    unzip $broker_dir/overview-broker.zip -d $broker_dir
  fi

  cf_login "$cf_api" "$cf_username" "$cf_password" "$cf_skip_cert_check"
  cf_target "$org" "$space"
  cf push "$broker_name" -p "$broker_dir/overview-broker-$commit"
  cf logout

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg service_broker "$broker_name" \
    --arg username admin \
    --arg password password \
    --arg url "https://$broker_name.$cf_apps_domain" \
    '{
      command: "create-service-broker",
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

it_can_unbind_a_synchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$sync_service_instance

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "unbind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_unbind_an_asynchronous_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$async_service_instance

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    command: "unbind-service",
    org: $org,
    space: $space,
    app_name: $app_name,
    service_instance: $service_instance
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_is_app_bound_to_service "$app_name" "$service_instance"
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

cleanup_test_orgs() {
  cf_login "$cf_api" "$cf_username" "$cf_password" "$cf_skip_cert_check"
  while read -r org; do
    cf_delete_org "$org"
  done < <(cf orgs | grep "$testprefix Org" || true)
}

cleanup_test_users() {
  cf_login "$cf_api" "$cf_username" "$cf_password" "$cf_skip_cert_check"

  local next_url='/v2/users?order-direction=asc&page=1'
  while [ "$next_url" != "null" ]; do

    local output=$(CF_TRACE=false cf curl "$next_url")
    local username=

    while read -r username; do
      cf_delete_user "$username"
    done < <(echo "$output" | jq -r --arg userprefix "$testprefix-" '.resources[] | select(.entity.username|startswith($userprefix)?) | .entity.username')

    next_url=$(echo "$output" | jq -r '.next_url')
  done
}

# cleanup failed tests
run cleanup_test_orgs
run cleanup_test_users

run it_can_create_an_org
run it_can_create_a_space

run it_can_create_a_user_with_password
run it_can_create_a_user_with_origin
run it_can_create_users_from_file

run it_can_create_a_service_broker_space_scoped
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

run it_can_create_a_domain

run it_can_push_an_app_no_start

run it_can_bind_user_provided_service_with_credentials_string
run it_can_bind_user_provided_service_with_credentials_file
run it_can_bind_user_provided_service_with_syslog
run it_can_bind_user_provided_service_with_route

run it_can_create_a_synchronous_service
# run again to prove that it won't error out if it already exists
run it_can_create_a_synchronous_service
run it_can_bind_a_synchronous_service

run it_can_create_an_asynchronous_service
# run again to prove that it won't error out if it already exists
run it_can_create_an_asynchronous_service
run it_can_bind_an_asynchronous_service

run it_can_disable_service_instance_sharing
run it_can_enable_service_instance_sharing
run it_can_disable_service_instance_sharing
run it_can_enable_service_instance_sharing

run it_can_start_an_app
run it_can_zero_downtime_push

run it_can_run_a_task_with_disk_quota
run it_can_run_a_task_with_memory
run it_can_run_a_task_with_name
run it_can_run_a_task

run it_can_scale_an_app_instances
run it_can_scale_an_app_disk_quota
run it_can_scale_an_app_memory
run it_can_scale_an_app

run it_can_restart_an_app
run it_can_restage_an_app

run it_can_map_a_route
run it_can_map_a_route_with_hostname
run it_can_map_a_route_with_hostname_and_path

run it_can_unbind_a_synchronous_service
run it_can_unbind_an_asynchronous_service

run it_can_unmap_a_route_with_hostname_and_path
run it_can_unmap_a_route_with_hostname
run it_can_unmap_a_route

run it_can_delete_an_app

run it_can_delete_a_domain

run it_can_delete_a_synchronous_service
run it_can_delete_an_asynchronous_service

run it_can_delete_a_user_with_origin
run it_can_delete_a_user_with_password

run it_can_delete_a_space_and_org

run cleanup_test_users
