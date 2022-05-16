#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/error-codes.sh

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

  It 'can show logs on a failed push'
    push_app_with_insufficient_disk_quota() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  memory: 64M
        #|  disk_quota: 1M
        #|  show_app_log: true
      )
      put "$config"
    }
    When call push_app_with_insufficient_disk_quota
    The status should eq $E_PUSH_FAILED_WITH_APP_LOGS_SHOWN
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Retrieving logs"
    Assert not test::is_app_started "$app_name" "$org" "$space"
  End
End
