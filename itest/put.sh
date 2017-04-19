#!/bin/bash

set -e

test_dir=$(dirname $0)

source $test_dir/helpers.sh

# WARNING: These tests will CREATE and then DESTROY test orgs and spaces
testprefix=cfclitest
timestamp=$(date +%s)
org=$testprefix-org-$timestamp
space=$testprefix-space-$timestamp
mysql_si=$testprefix-db-$timestamp
rabbitmq_si=$testprefix-rabbitmq-$timestamp
service_registry_si=$testprefix-service_registry-$timestamp
config_server_si=$testprefix-config_server-$timestamp
circuit_breaker_dashboard_si=$testprefix-circuit_breaker_dashboard-$timestamp
app_name=$testprefix-app-$timestamp

# cf dev start -s all
source=$(jq -n \
--arg org "$org" \
--arg space "$space" \
'{
  source: {
    api: "https://api.local.pcfdev.io",
    skip_cert_check: "true",
    username: "admin",
    password: "admin",
    org: $org,
    space: $space
  }
}')

it_can_create_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  '{
    create_org: {
      org: $org
    }
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
    create_space: {
      org: $org,
      space: $space
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

it_can_create_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-mysql",
      plan: "512mb",
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$mysql_si"
}

it_can_create_a_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$rabbitmq_si" \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-rabbitmq",
      plan: "standard",
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$rabbitmq_si"
}

it_can_create_a_service_registry() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_registry_si" \
  --arg configuration '{"count": 1}' \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-service-registry",
      plan: "standard",
      service_instance: $service_instance,
      configuration: $configuration,
      wait_for_service: true
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$service_registry_si"
}

it_can_create_a_config_server() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$config_server_si" \
  --arg configuration '{"count": 1, "git": {"uri": "https://github.com/patrickcrocker/cf-SpringBootTrader-config.git"}}' \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-config-server",
      plan: "standard",
      service_instance: $service_instance,
      configuration: $configuration,
      wait_for_service: true
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$config_server_si"
}

it_can_create_a_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  --arg configuration '{"count": 1}' \
  '{
    create_service: {
      org: $org,
      space: $space,
      service: "p-circuit-breaker-dashboard",
      plan: "standard",
      service_instance: $service_instance,
      configuration: $configuration
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_wait_for_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  '{
    wait_for_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_push_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  create_static_app "$app_name" "$working_dir"

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    push: {
      org: $org,
      space: $space,
      app_name: $app_name,
      hostname: $app_name,
      path: "static-app/content",
      manifest: "static-app/manifest.yml",
      no_start: "true"
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf app "$app_name" --guid
}

it_can_start_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    start: {
      org: $org,
      space: $space,
      app_name: $app_name,
      staging_timeout: 15,
      startup_timeout: 5
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  curl --output /dev/null --silent --head --fail http://$app_name.local.pcfdev.io/
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

  curl --output /dev/null --silent --head --fail http://$app_name.local.pcfdev.io/
}

it_can_bind_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$mysql_si

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    bind_service: {
      org: $org,
      space: $space,
      app_name: $app_name,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_bind_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local service_instance=$rabbitmq_si

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  --arg service_instance "$service_instance" \
  '{
    bind_service: {
      org: $org,
      space: $space,
      app_name: $app_name,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_is_app_bound_to_service "$app_name" "$service_instance"
}

it_can_delete_an_app() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg app_name "$app_name" \
  '{
    delete: {
      org: $org,
      space: $space,
      app_name: $app_name,
      delete_mapped_routes: "true"
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! curl --output /dev/null --silent --head --fail http://$app_name.local.pcfdev.io/
}

it_can_delete_a_mysql_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$mysql_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$mysql_si"
}

it_can_delete_a_rabbitmq_service() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$rabbitmq_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$rabbitmq_si"
}

it_can_delete_a_circuit_breaker_dashboard() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$circuit_breaker_dashboard_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$circuit_breaker_dashboard_si"
}

it_can_delete_a_config_server() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$config_server_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$config_server_si"
}

it_can_delete_a_service_registry() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  --arg service_instance "$service_registry_si" \
  '{
    delete_service: {
      org: $org,
      space: $space,
      service_instance: $service_instance
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_service_exists "$service_registry_si"
}

it_can_delete_a_space() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  --arg space "$space" \
  '{
    delete_space: {
      org: $org,
      space: $space
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_space_exists "$org" "$space"
}

it_can_delete_an_org() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg org "$org" \
  '{
    delete_org: {
      org: $org
    }
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  ! cf_org_exists "$space"
}

it_can_use_command_syntax() {
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

it_can_use_commands_syntax() {
  local working_dir=$(mktemp -d $TMPDIR/put-src.XXXXXX)

  local params=$(jq -n \
  --arg service_instance "$mysql_si" \
  '{
    commands: [
      {
        command: "create-space",
      },
      {
        command: "create-service",
        service: "p-mysql",
        plan: "512mb",
        service_instance: $service_instance
      }
    ]
  }')

  local config=$(echo $source | jq --argjson params "$params" '.params = $params')

  put_with_params "$config" "$working_dir" | jq -e '
    .version | keys == ["timestamp"]
  '

  cf_space_exists "$org" "$space"
}

cleanup_failed_tests() {
  orgs=$(cf orgs | grep "$testprefix-org" || true)
  for org in $orgs; do
    cf delete-org "$org" -f
  done
}

run cleanup_failed_tests
run it_can_create_an_org
run it_can_create_a_space
run it_can_create_a_mysql_service
run it_can_create_a_rabbitmq_service
run it_can_create_a_service_registry
run it_can_create_a_config_server
run it_can_create_a_circuit_breaker_dashboard
# run again to prove that it won't error out if it already exists
run it_can_create_a_circuit_breaker_dashboard
run it_can_wait_for_circuit_breaker_dashboard
run it_can_push_an_app
run it_can_bind_mysql_service
run it_can_bind_rabbitmq_service
run it_can_start_an_app
run it_can_zero_downtime_push
run it_can_delete_an_app
run it_can_delete_a_circuit_breaker_dashboard
run it_can_delete_a_config_server
run it_can_delete_a_service_registry
run it_can_delete_a_rabbitmq_service
run it_can_delete_a_mysql_service
run it_can_delete_a_space
run it_can_delete_an_org
run it_can_use_command_syntax
run it_can_use_commands_syntax
run it_can_delete_an_org
