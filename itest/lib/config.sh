
set -eu
set -o pipefail

# export CF_CLI_RESOURCE_PROFILE=/path/to/file/that/exports/script/vars.env
if [ -f "${CF_CLI_RESOURCE_PROFILE:-}" ]; then
  source "$CF_CLI_RESOURCE_PROFILE"
fi

: "${CCR_CF_SYSTEM_DOMAIN:?}"
: "${CCR_CF_APPS_DOMAIN:?}"
: "${CCR_CF_SKIP_CERT_CHECK:?}"
: "${CCR_CF_USERNAME:?}"
: "${CCR_CF_PASSWORD:?}"
: "${CCR_CF_CLIENT_ID:?}"
: "${CCR_CF_CLIENT_SECRET:?}"
: "${CCR_SYNC_SERVICE:?}"
: "${CCR_SYNC_PLAN_1:?}"
: "${CCR_SYNC_PLAN_2:?}"
: "${CCR_SYNC_CONFIGURATION_1:=}"
: "${CCR_SYNC_CONFIGURATION_2:=}"
: "${CCR_ASYNC_SERVICE:?}"
: "${CCR_ASYNC_PLAN_1:?}"
: "${CCR_ASYNC_PLAN_2:?}"
: "${CCR_ASYNC_CONFIGURATION_1:=}"
: "${CCR_ASYNC_CONFIGURATION_2:=}"
: "${CCR_SHARE_SERVICE:?}"
: "${CCR_SHARE_PLAN:?}"
: "${CCR_SHARE_CONFIGURATION:=}"
: "${CCR_DOCKER_PRIVATE_IMAGE:?}"
: "${CCR_DOCKER_PRIVATE_USERNAME:?}"
: "${CCR_DOCKER_PRIVATE_PASSWORD:?}"
: "${CCR_SERVICE_KEY_SERVICE:?}"
: "${CCR_SERVICE_KEY_PLAN:?}"
: "${CCR_CF_CLI_VERSION:=6}"

CCR_CF_API="https://api.$CCR_CF_SYSTEM_DOMAIN"

CCR_SOURCE=$(jq -n \
--arg api "$CCR_CF_API" \
--arg skip_cert_check "$CCR_CF_SKIP_CERT_CHECK" \
--arg username "$CCR_CF_USERNAME" \
--arg password "$CCR_CF_PASSWORD" \
--arg cf_cli_version "$CCR_CF_CLI_VERSION" \
'{
  source: {
    api: $api,
    skip_cert_check: $skip_cert_check,
    username: $username,
    password: $password,
    cf_cli_version: $cf_cli_version,
    cf_color: true,
    cf_dial_timeout: 5,
    cf_trace: false
  }
}')
