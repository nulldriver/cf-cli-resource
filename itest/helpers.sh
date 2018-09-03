#!/bin/bash

set -eu
set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/cf-cli-tests.XXXXXX)
# Use a different CF_HOME for sessions, but keep the original plugins folder
export CF_HOME=$TMPDIR_ROOT
export CF_PLUGIN_HOME=$HOME

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

run() {
  export TMPDIR=$(mktemp -d $TMPDIR_ROOT/cf-cli-tests.XXXXXX)
  cf logout
  # convert multiple args to single arg so printf doesn't output multiple lines
  printf 'running \e[33m%s\e[0m...\n' "$(echo "$@")"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

assert_equals() {
  local expected=${1:?}
  local actual=${2:?}
  if [ ! "$actual" = "$expected" ]; then
    echo "expected: $expected but was: $actual"
    return 1
  fi
}

create_static_app() {
  local app_name=$1
  local working_dir=$2

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
  local config=$1
  local working_dir=$2
  echo $config | $resource_dir/out "$working_dir" | tee /dev/stderr
}

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
    manifest: "static-app/manifest.yml"
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_started "$app_name"
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

setup_integration_tests() {
  run it_can_create_an_org
  run it_can_create_a_space
}

teardown_integration_tests() {
  run it_can_delete_a_space_and_org
}

cleanup_failed_integration_tests() {
  run cleanup_test_orgs
  run cleanup_test_users
}
