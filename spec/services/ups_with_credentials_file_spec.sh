#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    service_instance=$(generate_test_name_with_spaces)
    fixture=$(load_fixture "user-provided-service")

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

  It 'can create ups with credentials file'
    cups_with_credentials_file() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  credentials: $fixture/credentials.json
      )
      put "$config"
    }
    When call cups_with_credentials_file
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
    Assert [ "$(jq --sort-keys . "$fixture/credentials.json")" == "$(test::get_user_provided_vcap_service "$app_name" "$service_instance" "$org" "$space" | jq --sort-keys .credentials)" ]
  End

  It 'can update ups with credentials file'
    uups_with_credentials_file() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  credentials: $fixture/updated-credentials.json
      )
      put "$config"
    }
    When call uups_with_credentials_file
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating user provided service"
    Assert test::service_exists "$service_instance" "$org" "$space"
    Assert [ "$(jq --sort-keys . "$fixture/updated-credentials.json")" == "$(test::get_user_provided_vcap_service "$app_name" "$service_instance" "$org" "$space" | jq --sort-keys .credentials)" ]
  End
End
