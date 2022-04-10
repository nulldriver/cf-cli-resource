#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

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

  It 'can push an app without starting'
    push_app_no_start() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  disk_quota: 64M
        #|  memory: 64M
        #|  no_start: true
      )
      put "$config"
    }
    When call push_app_no_start
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_stopped "$app_name" "$org" "$space"
  End

  It 'can start an app'
    start_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: start
        #|  app_name: $app_name
      )
      put "$config"
    }
    When call start_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Starting app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can stop an app'
    stop_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: stop
        #|  app_name: $app_name
      )
      put "$config"
    }
    When call stop_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Stopping app"
    Assert test::is_app_stopped "$app_name" "$org" "$space"
  End
End
