#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    service_instance=$(generate_test_name_with_spaces)
    credentials='{"username":"admin","password":"pa55woRD"}'
    updated_credentials='{"username":"admin","password":"pa$$woRD"}'

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

  It 'can create ups with credentials string'
    cups_with_credentials_string() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  credentials: $credentials
      )
      put "$config"
    }
    When call cups_with_credentials_string
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user provided service"
    Assert test::service_exists "$service_instance" "$org" "$space"
  End

  It 'can push an app with bound service'
    push_app() {
        local fixture=$(load_fixture "static-app")
        local config=$(
            %text:expand
            #|$source
            #|params:
            #|  command: push
            #|  path: $fixture/dist
            #|  no_start: true
            #|  manifest:
            #|    applications:
            #|    - name: $app_name
            #|      memory: 64M
            #|      disk_quota: 64M
            #|      services:
            #|      - $service_instance
        )
        put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing"
    Assert [ "$(echo "$credentials" | jq --sort-keys)" == "$(test::get_user_provided_vcap_service "$app_name" "$service_instance" "$org" "$space" | jq --sort-keys .credentials)" ]
  End

  It 'can update ups with credentials string'
    uups_with_credentials_string() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  credentials: $updated_credentials
      )
      put "$config"
    }
    When call uups_with_credentials_string
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating user provided service"
    Assert test::service_exists "$service_instance" "$org" "$space"
    Assert [ "$(echo "$updated_credentials" | jq --sort-keys)" == "$(test::get_user_provided_vcap_service "$app_name" "$service_instance" "$org" "$space" | jq --sort-keys .credentials)" ]
  End
End
