
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

cf_api="https://api.$CF_SYSTEM_DOMAIN"
cf_apps_domain=$CF_APPS_DOMAIN
cf_skip_cert_check=$CF_SKIP_CERT_CHECK
cf_username=$CF_USERNAME
cf_password=$CF_PASSWORD
cf_color=true
cf_dial_timeout=5
cf_trace=false

source=$(jq -n \
--arg api "$cf_api" \
--arg skip_cert_check "$cf_skip_cert_check" \
--arg username "$cf_username" \
--arg password "$cf_password" \
--arg cf_color "$cf_color" \
--arg cf_dial_timeout "$cf_dial_timeout" \
--arg cf_trace "$cf_trace" \
'{
  source: {
    api: $api,
    skip_cert_check: $skip_cert_check,
    username: $username,
    password: $password,
    cf_color: $cf_color,
    cf_dial_timeout: $cf_dial_timeout,
    cf_trace: $cf_trace
  }
}')
