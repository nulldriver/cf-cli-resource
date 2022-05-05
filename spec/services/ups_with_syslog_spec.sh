#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    service_instance=$(generate_test_name_with_spaces)
    binding_name=$(generate_test_name_with_hyphens)
    syslog_drain_url="syslog://example.com"
    updated_syslog_drain_url="syslog://illustration.com"

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

  It 'can create ups with syslog'
    cups_with_syslog() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  syslog_drain_url: $syslog_drain_url
      )
      put "$config"
    }
    When call cups_with_syslog
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user provided service"
    Assert test::service_exists "$service_instance" "$org" "$space"
  End

  It 'can push an app for syslog tests'
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
        )
        put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing"
    Assert test::app_exists "$app_name" "$org" "$space"
  End

  It 'can bind a service to an app'
    bind_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: bind-service
        #|  app_name: $app_name
        #|  service_instance: $service_instance
        #|  binding_name: $binding_name
      )
      if cf::is_cf8; then
        config=$(
          %text:expand
          #|$config
          #|  wait: true
        )
      fi
      put "$config"
    }
    When call bind_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Binding service"
    if cf::is_cf8; then
      The error should include 'Waiting for the operation to complete'
    fi
    Assert test::is_app_bound_to_service "$app_name" "$service_instance" "$org" "$space"
    Assert [ "$syslog_drain_url" == "$(test::get_user_provided_vcap_service "$app_name" "$binding_name" "$org" "$space" | jq -r .syslog_drain_url)" ]
  End

  It 'can update ups with syslog'
    uups_with_syslog() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  service_instance: $service_instance
        #|  syslog_drain_url: $updated_syslog_drain_url
      )
      put "$config"
    }
    When call uups_with_syslog
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating user provided service"
    Assert test::service_exists "$service_instance" "$org" "$space"
    Assert [ "$updated_syslog_drain_url" == "$(test::get_user_provided_vcap_service "$app_name" "$binding_name" "$org" "$space" | jq -r .syslog_drain_url)" ]
  End

  It 'can unbind a service to an app'
    unbind_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unbind-service
        #|  app_name: $app_name
        #|  service_instance: $service_instance
      )
      if cf::is_cf8; then
        config=$(
          %text:expand
          #|$config
          #|  wait: true
        )
      fi
      put "$config"
    }
    When call unbind_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Unbinding app $app_name from service $service_instance"
    if cf::is_cf8; then
      The error should include 'Waiting for the operation to complete'
    fi
    Assert not test::is_app_bound_to_service "$app_name" "$service_instance" "$org" "$space"
  End
End
