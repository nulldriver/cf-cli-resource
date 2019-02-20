
set -eu
set -o pipefail

test_dir=$(dirname $0)

export TMPDIR_ROOT=$(mktemp -d /tmp/cf-cli-tests.XXXXXX)
export CF_HOME=$TMPDIR_ROOT  # Use a unique CF_HOME for sessions
export CF_PLUGIN_HOME=$HOME  # But keep the original plugins folder

readonly test_prefix=cfclitest
readonly test_id=$($test_dir/bashids -e -s "$(uuidgen)" -l 10 "$RANDOM")

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    printf '\e[41;33;1mFailure encountered!\e[0m\n'
  fi
  rm -rf $TMPDIR_ROOT
}

trap on_exit EXIT

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
if [ -d "$base_dir/assets" ]; then
  resource_dir=$base_dir/assets
else
  resource_dir=/opt/resource
fi

source $resource_dir/cf-functions.sh
source $(dirname $0)/assert.sh

run() {
  export TMPDIR=$(mktemp -d $TMPDIR_ROOT/cf-cli-tests.XXXXXX)
  cf logout
  # convert multiple args to single arg so printf doesn't output multiple lines
  printf 'running \e[33m%s\e[0m...\n' "$(echo "$@")"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

generate_test_name_with_spaces() {
  echo "$test_prefix $1 $test_id"
}

generate_test_name_with_hyphens() {
  echo "$test_prefix-${1// /-}-$test_id"
}

app_to_hostname() {
  echo "${1// /-}" | awk '{print tolower($0)}'
}

create_static_app() {
  local app_name=${1:?app_name null or not set}
  local working_dir=${2:?working_dir null or not set}

  mkdir -p "$working_dir/static-app/content"

  echo "Hello" > "$working_dir/static-app/content/index.html"

  cat <<EOF >"$working_dir/static-app/manifest.yml"
---
applications:
- name: $app_name
  memory: 64M
  disk_quota: 64M
  instances: 1
  path: content
  buildpack: staticfile_buildpack
EOF
}

put_with_params() {
  local config=${1:?config null or not set}
  local working_dir=${2:?working_dir null or not set}

  echo $config | $resource_dir/out "$working_dir" | tee /dev/stderr
}

it_can_create_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  '{
    command: "create-org",
    org: $org
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert::success cf_org_exists "$1"
}

it_can_create_a_space() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  '{
    command: "create-space",
    org: $org,
    space: $space
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert::success cf_space_exists "$1" "$2"
}

# This test showcases the multi-command syntax
it_can_delete_a_space_and_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
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

  assert::failure cf_space_exists "$1" "$2"
  assert::failure cf_org_exists "$1"
}

it_can_push_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  create_static_app "$3" "$working_dir"

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  --arg app_name "$3" \
  '{
    command: "push",
    org: $org,
    space: $space,
    app_name: $app_name,
    hostname: $app_name,
    path: "static-app/content",
    manifest: "static-app/manifest.yml"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert::success cf_is_app_started "$3"
}

it_can_delete_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  --arg app_name "$3" \
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

  assert::failure cf_app_exists "$3"
}

it_can_create_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service=${3:?service null or not set}
  local plan=${4:?plan null or not set}
  local service_instance=${5:?service_instance null or not set}
  local configuration=${6:-}
  local wait_for_service=${7:-}
  local update_service=${8:-}

  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service "$service" \
  --arg plan "$plan" \
  --arg service_instance "$service_instance" \
  '{
    command: "create-service",
    org: $org,
    space: $space,
    service: $service,
    plan: $plan,
    service_instance: $service_instance
  }')

  [ -n "$configuration" ]    && params=$(echo $params | jq --arg value "$configuration"    '.configuration    = $value')
  [ -n "$wait_for_service" ] && params=$(echo $params | jq --arg value "$wait_for_service" '.wait_for_service = $value')
  [ -n "$update_service" ]   && params=$(echo $params | jq --arg value "$update_service"   '.update_service   = $value')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')
  put_with_params "$config" "$working_dir" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf_service_exists "$service_instance"
  assert::equals "$plan" "$(cf_get_service_instance_plan "$service_instance")"
}

it_can_update_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service_instance=${3:?service_instance null or not set}
  local plan=${4:-}
  local configuration=${5:-}
  local tags=${6:-}
  local wait_for_service=${7:-false}

  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_instance" \
  --arg plan "$plan" \
  --arg configuration "$configuration" \
  --arg tags "$tags" \
  --arg wait_for_service "$wait_for_service" \
  '{
    command: "update-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    plan: $plan,
    configuration: $configuration,
    tags: $tags,
    wait_for_service: $wait_for_service
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf_service_exists "${service_instance}"
  assert::equals "$plan" "$(cf_get_service_instance_plan "$service_instance")"
  assert::equals "$tags" "$(cf_get_service_instance_tags "$service_instance")"
  #TODO: currently there is no way that I know of to retrieve an si's configuration...
}

it_can_bind_a_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  --arg app_name "$3" \
  --arg service_instance "$4" \
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

  assert::success cf_is_app_bound_to_service "$3" "$4"
}

it_can_unbind_a_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  --arg app_name "$3" \
  --arg service_instance "$4" \
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

  assert::failure cf_is_app_bound_to_service "$3" "$4"
}

it_can_delete_a_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$1" \
  --arg space "$2" \
  --arg service_instance "$3" \
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

  assert::failure cf_service_exists "$3"
}

it_can_enable_feature_flag() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg feature_flag "$1" \
  '{
    command: "enable-feature-flag",
    feature_name: $feature_flag
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert::success cf_is_feature_flag_enabled "$1"
}

it_can_disable_feature_flag() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg feature_flag "$1" \
  '{
    command: "disable-feature-flag",
    feature_name: $feature_flag
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  assert::success cf_is_feature_flag_disabled "$1"
}

cleanup_test_orgs() {
  cf_api "$cf_api" "$cf_skip_cert_check"
  cf_auth_user "$cf_username" "$cf_password"

  while read -r org; do
    cf_delete_org "$org"
  done < <(cf orgs | grep "$test_prefix " || true)
}

cleanup_test_users() {
  cf_api "$cf_api" "$cf_skip_cert_check"
  cf_auth_user "$cf_username" "$cf_password"

  local next_url='/v2/users?order-direction=asc&page=1'
  while [ "$next_url" != "null" ]; do

    local output=$(CF_TRACE=false cf curl "$next_url")
    local username=

    while read -r username; do
      cf_delete_user "$username"
    done < <(echo "$output" | jq -r --arg userprefix "$test_prefix-" '.resources[] | select(.entity.username|startswith($userprefix)?) | .entity.username')

    next_url=$(echo "$output" | jq -r '.next_url')
  done
}

cleanup_service_brokers() {
  cf_api "$cf_api" "$cf_skip_cert_check"
  cf_auth_user "$cf_username" "$cf_password"

  while read -r broker; do
    cf_delete_service_broker "$broker"
  done < <(cf curl /v2/service_brokers | jq -r --arg brokerprefix "$test_prefix" '.resources[] | select(.entity.name | startswith($brokerprefix)) | .entity.name')
}

setup_integration_tests() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  run it_can_create_an_org \"$org\"
  run it_can_create_a_space \"$org\" \"$space\"
}

teardown_integration_tests() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  run it_can_delete_a_space_and_org \"$org\" \"$space\"
}

