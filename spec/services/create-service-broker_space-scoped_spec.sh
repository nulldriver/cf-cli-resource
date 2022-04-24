#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    domain=$(get_env_var "CCR_CF_APPS_DOMAIN") || error_and_exit "[ERROR] required env var not set: CCR_CF_APPS_DOMAIN"

    service_broker=$(generate_test_name_with_spaces)
    service_broker_url="https://$(app_to_hostname "$app_name").$domain"

    source=$(get_source_config "$org" "$space") || error_and_exit "[ERROR] error loading source json config"

    test::login
    test::create_org_and_space "$org" "$space"
  }

  teardown() {
    test::delete_org_and_space "$org" "$space"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can push a service broker app'
    push_app() {
      local fixture=$(load_fixture "overview-broker")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture
        #|  memory: 256M
        #|  disk_quota: 256M
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can create a service broker space scoped'
    create_service_broker_space_scoped() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service-broker
        #|  service_broker: $service_broker
        #|  username: admin
        #|  password: password
        #|  url: $service_broker_url
        #|  space_scoped: true
      )
      put "$config"
    }
    When call create_service_broker_space_scoped
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating service broker $service_broker"
    Assert test::service_broker_exists "$service_broker" "$org" "$space"
  End
  Dump

  It 'can update a service broker space scoped'
    update_service_broker_space_scoped() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service-broker
        #|  service_broker: $service_broker
        #|  username: admin
        #|  password: password
        #|  url: $service_broker_url
        #|  space_scoped: true
      )
      put "$config"
    }
    When call update_service_broker_space_scoped
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating service broker $service_broker"
    Assert test::service_broker_exists "$service_broker" "$org" "$space"
  End

  It 'can delete a service broker'
    delete_service_broker() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-service-broker
        #|  service_broker: $service_broker
      )
      put "$config"
    }
    When call delete_service_broker
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting service broker $service_broker"
    Assert not test::service_broker_exists "$service_broker" "$org" "$space"
  End
End
