#shellcheck shell=sh

set -euo pipefail

task "cleanup" "Cleanup Failed Tests"

TEST_PREFIX="cfclitest"

login() {
  : "${CCR_CF_API:?}"
  : "${CCR_CF_USERNAME:?}"
  : "${CCR_CF_PASSWORD:?}"
  : "${CCR_CF_CLI_VERSION:=6}"

  cf::api "$CCR_CF_API"
  cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"
}

cleanup_test_orgs() {
  echo "Deleting test orgs..."
  while read -r org; do
    cf::delete_org "$org"
  done < <(cf::cf orgs | grep "$TEST_PREFIX " || true)
}

cleanup_test_users() {
  echo "Deleting test users..."
  local next_url='/v2/users?order-direction=asc&page=1'
  while [ "$next_url" != "null" ]; do

    local output=$(cf::curl "$next_url")
    local username=

    while read -r username; do
      cf::delete_user "$username"
    done < <(echo "$output" | jq -r --arg userprefix "$TEST_PREFIX-" '.resources[] | select(.entity.username|startswith($userprefix)?) | .entity.username')

    next_url=$(echo "$output" | jq -r '.next_url')
  done
}

cleanup_service_brokers() {
  echo "Deleting test service brokers..."
  while read -r broker; do
    cf::delete_service_broker "$broker"
  done < <(cf::curl /v2/service_brokers | jq -r --arg brokerprefix "$TEST_PREFIX" '.resources[] | select(.entity.name | startswith($brokerprefix)) | .entity.name')
}

cleanup_buildpacks() {
  echo "Deleting test buildpacks..."
  while read -r buildpack; do
    cf::cf delete-buildpack -f "$buildpack"
  done < <(cf::curl /v2/buildpacks | jq -r --arg buildpackprefix "$TEST_PREFIX" '.resources[] | select(.entity.name | startswith($buildpackprefix)) | .entity.name')
}

cleanup_task() {
  echo "Cleaning up failed tests..."

  export CF_HOME=$(mktemp -d "$TMPDIR/cf_home_tests.XXXXXX")

  on_exit() {
    rm -rf $CF_HOME
  }
  trap on_exit EXIT

  source $SHELLSPEC_PROJECT_ROOT/resource/lib/cf-functions.sh

  login
  cleanup_test_orgs
  cleanup_test_users
  cleanup_service_brokers
  cleanup_buildpacks

  echo "Cleanup complete."
}
