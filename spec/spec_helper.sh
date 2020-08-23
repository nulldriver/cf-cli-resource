#shellcheck shell=bash

set -euo pipefail

export TMPDIR=$SHELLSPEC_TMPBASE
export CF_HOME=$(mktemp -d "$TMPDIR/cf_home_tests.XXXXXX")

BASE_DIR=$SHELLSPEC_PROJECT_ROOT
FIXTURE=$SHELLSPEC_SPECDIR/fixture

shellspec_spec_helper_configure() {
  shellspec_import 'support/json_matcher'

  # Negation helper function
  not() {
    ! "$@"
  }

  # Executes command capturing status and all output (stdout and stderr).
  # If command failes output is echoed and returns failure status code.
  quiet() {
    local output=
    if ! output=$("$@" 2>&1); then
      local status=$?
      echo "[ERROR] $output"
      exit $status
    fi
  }

  initialize_source_config() {
    : "${CCR_CF_API:?}"
    : "${CCR_CF_USERNAME:?}"
    : "${CCR_CF_PASSWORD:?}"
    : "${CCR_CF_CLI_VERSION:=6}"

    jq -n \
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
  }

  login_for_test_assertions() {
    quiet cf::api "$(echo $CCR_SOURCE | jq -re '.source.api')"
    quiet cf::auth_user "$(echo $CCR_SOURCE | jq -re '.source.username')" "$(echo $CCR_SOURCE | jq -re '.source.password')"
  }

  put_with_params() {
    local params=${1:?params null or not set}
    local working_dir=${2:-$(mktemp -d $TMPDIR/put-src.XXXXXX)}

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
