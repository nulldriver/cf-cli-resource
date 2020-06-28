
set -eu
set -o pipefail

base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

source "$base_dir/itest/lib/assert.sh"
source "$base_dir/resource/lib/cf-functions.sh"

export TMPDIR_ROOT=$(mktemp -d /tmp/cf-cli-tests.XXXXXX)
export CF_HOME=$TMPDIR_ROOT  # Use a unique CF_HOME for sessions
export CF_PLUGIN_HOME=$HOME  # But keep the original plugins folder

readonly test_prefix=cfclitest

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    printf '\e[41;33;1mFailure encountered!\e[0m\n'
  fi
  rm -rf $TMPDIR_ROOT
}

trap on_exit EXIT

describe() {
  printf '\e[33m%s\e[0m...\n' "$@"
}

run() {
  export TMPDIR=$(mktemp -d $TMPDIR_ROOT/cf-cli-tests.XXXXXX)
  if cf::is_logged_in; then
    cf::cf logout
  fi
  # convert multiple args to single arg so printf doesn't output multiple lines
  printf 'running \e[33m%s\e[0m...\n' "$(echo "$@")"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

generate_test_id() {
  "$base_dir/itest/lib/bashids" -e -s "$(uuidgen)" -l 10 "$RANDOM"
}

generate_test_name_with_spaces() {
  echo "$test_prefix $1 $(generate_test_id)"
}

generate_test_name_with_hyphens() {
  echo "$test_prefix-${1// /-}-$(generate_test_id)"
}

app_to_hostname() {
  echo "${1// /-}" | awk '{print tolower($0)}'
}

create_static_app() {
  local app_name=${1:?app_name null or not set}
  local manifest=${2:-}

  cd $(mktemp -d $TMPDIR/app.XXXXXX)

  mkdir -p "content"
  echo "Hello" > "content/index.html"
  touch "content/Staticfile"

  if [ -n "$manifest" ]; then
    echo "$manifest" >"manifest.yml"
  else
    cat <<EOF >"manifest.yml"
---
applications:
- name: $app_name
  memory: 64M
  disk_quota: 64M
  path: content
  buildpacks:
  - staticfile_buildpack
EOF
  fi

  pwd
}

create_static_app_with_vars() {
  local app_name=${1:?app_name null or not set}

  cd $(mktemp -d $TMPDIR/app.XXXXXX)

  mkdir -p "content"
  echo "Hello" > "content/index.html"

  cat <<EOF >"manifest.yml"
---
applications:
- name: $app_name
  memory: ((memory))
  disk_quota: 64M
  instances: ((instances))
  path: content
  buildpacks:
  - staticfile_buildpack
EOF

  cat <<EOF >"vars-file1.yml"
---
memory: 64M
EOF

  cat <<EOF >"vars-file2.yml"
---
instances: 1
EOF

  pwd
}

create_logging_route_service_app() {
  cd $(mktemp -d $TMPDIR/app.XXXXXX)

  wget -q https://github.com/nulldriver/logging-route-service/archive/master.zip -O logging-route-service.zip

  unzip -q logging-route-service.zip
  mv logging-route-service-*/* .
  rm -rf logging-route-service-*
  rm logging-route-service.zip

  pwd
}

create_bookstore_service_broker_app() {
  cd $(mktemp -d $TMPDIR/app.XXXXXX)

  wget -q https://github.com/nulldriver/bookstore-service-broker/archive/master.zip -O bookstore-service-broker.zip

  unzip -q bookstore-service-broker.zip
  mv bookstore-service-broker-*/* .
  rm -rf bookstore-service-broker-*
  rm bookstore-service-broker.zip

  pwd
}

create_service_broker_app() {
  cd $(mktemp -d $TMPDIR/app.XXXXXX)

  wget -q https://github.com/mattmcneeney/overview-broker/archive/master.zip -O overview-broker.zip

  unzip -q overview-broker.zip
  mv overview-broker-*/* .
  rm -rf overview-broker-*
  rm overview-broker.zip

  pwd
}

create_org_commands_file() {
  local org=${1:?org null or not set}

  cd $(mktemp -d $TMPDIR/org_commands.XXXXXX)

  cat > "commands.yml" <<-EOF
command: create-org
org: $org
EOF

  pwd
}

create_space_commands_file() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  cd $(mktemp -d $TMPDIR/space_commands.XXXXXX)

  cat > "commands.yml" <<-EOF
command: create-space
org: $org
space: $space
EOF

  pwd
}

create_delete_commands_file() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  cd $(mktemp -d $TMPDIR/delete_commands.XXXXXX)

  cat > "commands.yml" <<-EOF
commands:
- command: delete-space
  org: $org
  space: $space
- command: delete-org
  org: $org
EOF

  pwd
}

create_credentials_file() {

  cd $(mktemp -d $TMPDIR/commands_file.XXXXXX)

  echo \
  '{
    "username": "admin",
    "password": "pa55woRD"
  }' > credentials.json

  pwd
}

create_users_file() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  cd $(mktemp -d $TMPDIR/users_file.XXXXXX)

  cat << EOF > users.csv
Username,Password,Org,Space,OrgManager,BillingManager,OrgAuditor,SpaceManager,SpaceDeveloper,SpaceAuditor
$test_prefix-bulkload-user1,wasabi,$org,$space,x,x,x,x,x,x
$test_prefix-bulkload-user2,wasabi,$org,$space,,x,x,,x,x
$test_prefix-bulkload-user3,ldap,$org,$space,,,x,,x,
EOF

  pwd
}

download_file() {
  local url=${1:?url null or not set}

  cd $(mktemp -d $TMPDIR/download.XXXXXX)

  wget -q "$url"

  pwd
}

put_with_config() {
  local config=${1:?config null or not set}
  local working_dir=${2:-$(mktemp -d $TMPDIR/put-src.XXXXXX)}

  echo $config | "$base_dir/resource/out" "$working_dir" | tee /dev/stderr
}

put_with_params() {
  local source=${1:?source null or not set}
  local params=${2:?params null or not set}
  local working_dir=${3:-$(mktemp -d $TMPDIR/put-src.XXXXXX)}

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')
  put_with_config "$config" "$working_dir"
}

it_can_create_an_org() {
  local org=${1:?org null or not set}

  local params=$(jq -n \
  --arg org "$org" \
  '{
    command: "create-org",
    org: $org
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::org_exists "$org"
}

it_can_create_a_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    command: "create-space",
    org: $org,
    space: $space
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::space_exists "$org" "$space"
}

# This test showcases the multi-command syntax
it_can_delete_a_space_and_org() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::failure cf::space_exists "$org" "$space"
  assert::failure cf::org_exists "$org"
}

it_can_push_an_app() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}

  local project=$(create_static_app "$app_name")

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg path "$project" \
  --arg manifest "$project/manifest.yml" \
  '{
    command: "push",
    org: $org,
    space: $space,
    app_name: $app_name,
    path: $path,
    manifest: $manifest
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::is_app_started "$app_name"
}

it_can_delete_an_app() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::failure cf::app_exists "$app_name"
}

it_can_create_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service=${3:?service null or not set}
  local plan=${4:?plan null or not set}
  local service_instance=${5:?service_instance null or not set}
  local broker=${6:-}
  local configuration=${7:-}
  local wait_for_service=${8:-}
  local update_service=${9:-}

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

  [ -n "$broker" ]           && params=$(echo $params | jq --arg value "$broker"           '.broker           = $value')
  [ -n "$configuration" ]    && params=$(echo $params | jq --arg value "$configuration"    '.configuration    = $value')
  [ -n "$wait_for_service" ] && params=$(echo $params | jq --arg value "$wait_for_service" '.wait_for_service = $value')
  [ -n "$update_service" ]   && params=$(echo $params | jq --arg value "$update_service"   '.update_service   = $value')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::service_exists "$service_instance"
  assert::equals "$plan" "$(cf::get_service_instance_plan "$service_instance")"
}

it_can_create_a_user_provided_service_with_route() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service_instance=${3:?service_instance null or not set}
  local route_service_url=${4:?route_service_url null or not set}

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_instance" \
  --arg route_service_url "$route_service_url" \
  '{
    command: "create-user-provided-service",
    org: $org,
    space: $space,
    service_instance: $service_instance,
    route_service_url: $route_service_url
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::service_exists "$service_instance"
}

it_can_update_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service_instance=${3:?service_instance null or not set}
  local plan=${4:-}
  local configuration=${5:-}
  local tags=${6:-}
  local wait_for_service=${7:-false}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::service_exists "${service_instance}"
  assert::equals "$plan" "$(cf::get_service_instance_plan "$service_instance")"
  assert::equals "$tags" "$(cf::get_service_instance_tags "$service_instance")"
  #TODO: currently there is no way that I know of to retrieve an si's configuration...
}

it_can_bind_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}
  local service_instance=${4:?service_instance null or not set}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_unbind_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}
  local service_instance=${4:?service_instance null or not set}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::failure cf::is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_delete_a_service() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local service_instance=${3:?service_instance null or not set}

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

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::failure cf::service_exists "$service_instance"
}

it_can_enable_feature_flag() {
  local feature_flag=${1:?feature_flag null or not set}

  local params=$(jq -n \
  --arg feature_flag "$feature_flag" \
  '{
    command: "enable-feature-flag",
    feature_name: $feature_flag
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::is_feature_flag_enabled "$feature_flag"
}

it_can_disable_feature_flag() {
  local feature_flag=${1:?feature_flag null or not set}

  local params=$(jq -n \
  --arg feature_flag "$feature_flag" \
  '{
    command: "disable-feature-flag",
    feature_name: $feature_flag
  }')

  put_with_params "$CCR_SOURCE" "$params" | jq -e '.version | keys == ["timestamp"]'

  assert::success cf::is_feature_flag_disabled "$feature_flag"
}

cleanup_test_orgs() {
  cf::api "$CCR_CF_API" "$CCR_CF_SKIP_CERT_CHECK"
  cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"

  while read -r org; do
    cf::delete_org "$org"
  done < <(cf::cf orgs | grep "$test_prefix " || true)
}

cleanup_test_users() {
  cf::api "$CCR_CF_API" "$CCR_CF_SKIP_CERT_CHECK"
  cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"

  local next_url='/v2/users?order-direction=asc&page=1'
  while [ "$next_url" != "null" ]; do

    local output=$(cf::curl "$next_url")
    local username=

    while read -r username; do
      cf::delete_user "$username"
    done < <(echo "$output" | jq -r --arg userprefix "$test_prefix-" '.resources[] | select(.entity.username|startswith($userprefix)?) | .entity.username')

    next_url=$(echo "$output" | jq -r '.next_url')
  done
}

cleanup_service_brokers() {
  cf::api "$CCR_CF_API" "$CCR_CF_SKIP_CERT_CHECK"
  cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"

  while read -r broker; do
    cf::delete_service_broker "$broker"
  done < <(cf::curl /v2/service_brokers | jq -r --arg brokerprefix "$test_prefix" '.resources[] | select(.entity.name | startswith($brokerprefix)) | .entity.name')
}

cleanup_buildpacks() {
  cf::api "$CCR_CF_API" "$CCR_CF_SKIP_CERT_CHECK"
  cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"

  while read -r buildpack; do
    cf::cf delete-buildpack -f "$buildpack"
  done < <(cf::curl /v2/buildpacks | jq -r --arg buildpackprefix "$test_prefix" '.resources[] | select(.entity.name | startswith($buildpackprefix)) | .entity.name')
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
