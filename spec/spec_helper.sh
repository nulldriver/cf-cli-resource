#shellcheck shell=bash

set -euo pipefail

export TMPDIR=$SHELLSPEC_TMPBASE
export CF_HOME=$(mktemp -d "$TMPDIR/.cf.XXXXXX")

BASE_DIR=$SHELLSPEC_PROJECT_ROOT
FIXTURE=$SHELLSPEC_SPECDIR/fixture

DEFAULT_CF_CLI_VERSION=6

shellspec_spec_helper_configure() {
  shellspec_import 'support/json_matcher'

  error_and_exit() {
    echo "$1" >&3
    exit 1
  }

  # Dependency checks
  (( "${BASH_VERSINFO[0]}" >= 4 )) || error_and_exit "[ERROR] bash v4 or higher is required (found version $BASH_VERSION)"
  command -v jq >/dev/null || error_and_exit "[ERROR] unable to locate jq binary (https://stedolan.github.io/jq/)"
  command -v yq >/dev/null || error_and_exit "[ERROR] unable to locate yq binary (https://github.com/mikefarah/yq)"
  [[ "$(yq --version)" != "yq version 3"* ]] && error_and_exit "[ERROR] yq v3 is required (found $(yq --version))"

  # Negation helper function
  not() {
    ! "$@"
  }

  # Executes command capturing status and all output (stdout and stderr).
  # If command fails then output is echoed and failure status code is returned.
  quiet() {
    local output=
    if ! output=$("$@" 2>&1); then
      local status=${PIPESTATUS[0]}
      echo "[ERROR] $output"
      exit $status
    fi
  }

  yaml_to_json() {
    local yaml=${1:?yaml null or not set}
    echo "$yaml" | yq read - --tojson
  }

  load_fixture() {
    local fixture=${1:?fixture null or not set}

    if [ ! -d "$FIXTURE/$fixture" ]; then
      echo "[ERROR] Fixture not found: $FIXTURE/$fixture" >&2
      exit 1
    fi

    cd $(mktemp -d "$TMPDIR/$fixture.XXXXXX")
    cp -r "$FIXTURE/$fixture/." .

    pwd
  }

  initialize_source_config() {
    [ -z "${CCR_CF_API:-}" ] && error_and_exit "environment variable not set: CCR_CF_API"
    [ -z "${CCR_CF_USERNAME:-}" ] && error_and_exit "environment variable not set: CCR_CF_USERNAME"
    [ -z "${CCR_CF_PASSWORD:-}" ] && error_and_exit "environment variable not set: CCR_CF_PASSWORD"

    : "${CCR_CF_CLI_VERSION:=$DEFAULT_CF_CLI_VERSION}"

    CCR_SOURCE=$(jq -n \
      --arg api "$CCR_CF_API" \
      --arg username "$CCR_CF_USERNAME" \
      --arg password "$CCR_CF_PASSWORD" \
      --arg cf_cli_version "$CCR_CF_CLI_VERSION" \
      '{
        source: {
          api: $api,
          username: $username,
          password: $password,
          cf_cli_version: $cf_cli_version
        }
      }'
    )
  }

  initialize_source_config_with_uaa_origin() {
    initialize_source_config

    # Add origin to auth config
    CCR_SOURCE=$(echo "$CCR_SOURCE" | jq '.source.origin = "uaa"')
  }

  initialize_source_config_with_client_credentials() {
    [ -z "${CCR_CF_API:-}" ] && error_and_exit "environment variable not set: CCR_CF_API"
    [ -z "${CCR_CF_CLIENT_ID:-}" ] && error_and_exit "environment variable not set: CCR_CF_CLIENT_ID"
    [ -z "${CCR_CF_CLIENT_SECRET:-}" ] && error_and_exit "environment variable not set: CCR_CF_CLIENT_SECRET"

    : "${CCR_CF_CLI_VERSION:=$DEFAULT_CF_CLI_VERSION}"

    CCR_SOURCE=$(jq -n \
      --arg api "$CCR_CF_API" \
      --arg client_id "$CCR_CF_CLIENT_ID" \
      --arg client_secret "$CCR_CF_CLIENT_SECRET" \
      --arg cf_cli_version "$CCR_CF_CLI_VERSION" \
      '{
        source: {
          api: $api,
          client_id: $client_id,
          client_secret: $client_secret,
          cf_cli_version: $cf_cli_version
        }
      }'
    )
  }

  initialize_source_config_for_cf_home() {
    : "${CCR_CF_CLI_VERSION:=$DEFAULT_CF_CLI_VERSION}"

    CCR_SOURCE=$(jq -n \
      --arg cf_cli_version "$CCR_CF_CLI_VERSION" \
      '{
        source: {
          cf_cli_version: $cf_cli_version
        }
      }'
    )
  }

  initialize_docker_config() {
    [ -z "${CCR_DOCKER_PRIVATE_IMAGE:-}" ] && error_and_exit "environment variable not set: CCR_DOCKER_PRIVATE_IMAGE"
    [ -z "${CCR_DOCKER_PRIVATE_USERNAME:-}" ] && error_and_exit "environment variable not set: CCR_DOCKER_PRIVATE_USERNAME"
    [ -z "${CCR_DOCKER_PRIVATE_PASSWORD:-}" ] && error_and_exit "environment variable not set: CCR_DOCKER_PRIVATE_PASSWORD"
  }

  login_for_test_assertions() {
    local org=${1:-}
    local space=${2:-}

    [ -z "${CCR_CF_API:-}" ] && error_and_exit "environment variable not set: CCR_CF_API"
    [ -z "${CCR_CF_USERNAME:-}" ] && error_and_exit "environment variable not set: CCR_CF_USERNAME"
    [ -z "${CCR_CF_PASSWORD:-}" ] && error_and_exit "environment variable not set: CCR_CF_PASSWORD"

    cf::api "$CCR_CF_API"
    cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"

    if [ -n "$org" ] || [ -n "$space" ]; then
      cf::target "$org" "$space"
    fi
  }

  logout_for_test_assertions() {
    cf::cf logout
  }

  login_with_cf_home() {
    [ -z "${CCR_CF_API:-}" ] && error_and_exit "environment variable not set: CCR_CF_API"
    [ -z "${CCR_CF_USERNAME:-}" ] && error_and_exit "environment variable not set: CCR_CF_USERNAME"
    [ -z "${CCR_CF_PASSWORD:-}" ] && error_and_exit "environment variable not set: CCR_CF_PASSWORD"

    cd "$(mktemp -d "$TMPDIR/.cf_home.XXXXXX")"

    CF_HOME=$PWD cf::cf api "$CCR_CF_API" >/dev/null
    CF_HOME=$PWD cf::cf auth "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD" >/dev/null

    pwd
  }

  put() {
    local config=${1:?config null or not set}
    local working_dir=${2:-$(mktemp -d "$TMPDIR/put-src.XXXXXX")}

    yaml_to_json "$config" | "$BASE_DIR/resource/out" "$working_dir"
  }

  put_with_params() {
    local params=${1:?params null or not set}
    local working_dir=${2:-$(mktemp -d "$TMPDIR/put-src.XXXXXX")}

    local config=$(echo $CCR_SOURCE | jq --argjson params "$params" '.params = $params')
    echo $config | "$BASE_DIR/resource/out" "$working_dir"
  }

  generate_unique_id() {
    local uuid=$(uuidgen)
    echo "${uuid,,}" # make lowercase for macOS
  }

  generate_test_name_with_spaces() {
    echo "cfclitest $(generate_unique_id)"
  }

  generate_test_name_with_hyphens() {
    echo "cfclitest-$(generate_unique_id)"
  }

  create_org_and_space() {
    local org=${1:?org null or not set}
    local space=${2:?space null or not set}

    local params=$(jq -n \
      --arg org "$org" \
      --arg space "$space" \
      '{
        commands: [
          {
            command: "create-org",
            org: $org
          },
          {
            command: "create-space",
            org: $org,
            space: $space
          }
        ]
      }'
    )

    put_with_params "$params"
  }

  delete_org_and_space() {
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
            org: $org,
          }
        ]
      }'
    )

    put_with_params "$params"
  }
}

test::login() {
  quiet cf::api "$CCR_CF_API"
  quiet cf::auth_user "$CCR_CF_USERNAME" "$CCR_CF_PASSWORD"
}

test::logout() {
  quiet cf::cf logout
}

test::untarget() {
  echo "$(jq '.OrganizationFields = {"GUID":"", "Name":""} | .SpaceFields = {"GUID":"", "Name":"", "AllowSSH":false}' "$CF_HOME/.cf/config.json")" > "$CF_HOME/.cf/config.json"
}

test::create_org() {
  local org=${1:?org null or not set}
  quiet cf::create_org "$org"
}

test::delete_org() {
  local org=${1:?org null or not set}
  quiet cf::delete_org "$org"
}

test::create_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  quiet cf::create_space "$org" "$space"
}

test::is_app_started() {
  local app_name=${1:?app_name null or not set}
  local org=${2:?org null or not set}
  local space=${3:?space null or not set}

  quiet cf::target "$org" "$space"

  set +e
  cf::is_app_started "$app_name"
  status=$?
  set -e

  test::untarget

  return $status
}

test::is_app_mapped_to_route() {
  local app_name=${1:?app_name null or not set}
  local domain=${2:?domain null or not set}
  local org=${3:?org null or not set}
  local space=${4:?space null or not set}

  quiet cf::target "$org" "$space"

  set +e
  cf::is_app_mapped_to_route "$app_name" "$domain"
  status=$?
  set -e

  test::untarget

  return $status
}
