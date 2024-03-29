#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

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

  It 'can push an app'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  memory: 64M
        #|  disk_quota: 64M
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can restart an app'
    restart_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: restart
        #|  app_name: $app_name
      )
      put "$config"
    }
    When call restart_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Restarting app"
    The error should include "Stopping app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can restart an app using rolling strategy'
    Skip if 'using cf cli v6' cf::is_cf6
    restart_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: restart
        #|  app_name: $app_name
        #|  strategy: rolling
        #|  no_wait: true
      )
      put "$config"
    }
    When call restart_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Restarting app"
    The error should include "Waiting for app to deploy"
    The error should not include "Stopping app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End
End
