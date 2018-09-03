#!/bin/bash

set -eu
set -o pipefail

# export CF_CLI_RESOURCE_PROFILE=/path/to/file/that/exports/script/vars.env
if [ -f "${CF_CLI_RESOURCE_PROFILE:-}" ]; then
  source "$CF_CLI_RESOURCE_PROFILE"
fi

: "${CF_SYSTEM_DOMAIN:?}"
: "${CF_APPS_DOMAIN:?}"
: "${CF_SKIP_CERT_CHECK:?}"
: "${CF_USERNAME:?}"
: "${CF_PASSWORD:?}"
: "${SYNC_SERVICE:?}"
: "${SYNC_PLAN:?}"
: "${SYNC_CONFIGURATION:=}"
: "${ASYNC_SERVICE:?}"
: "${ASYNC_PLAN:?}"
: "${ASYNC_CONFIGURATION:=}"
: "${DOCKER_PRIVATE_IMAGE:?}"
: "${DOCKER_PRIVATE_USERNAME:?}"
: "${DOCKER_PRIVATE_PASSWORD:?}"

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

docker_private_image=$DOCKER_PRIVATE_IMAGE
docker_private_username=$DOCKER_PRIVATE_USERNAME
docker_private_password=$DOCKER_PRIVATE_PASSWORD

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
