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

  # happy path testing seems impossible due to no discernable output that 
  # indicates that an existing valid stack is being applied during the push.
  # So, instead we test by specifying a valid stack (`cf stacks`) that we 
  # actually don't have any compatible cells for in our ci environment (such 
  # as 'windows').  In this scenario the push will fail, but we can still 
  # query the cloud controller for the app's stack for our assertion.
  It 'can push an app with stack'
    push_app_with_windows_stack() {
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
        #|  stack: windows
      )
      put "$config"
    }
    When call push_app_with_windows_stack
    The status should be failure
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Found no compatible cell"
    Assert [ "windows" == "$(test::get_app_stack "$app_name" "$org" "$space")" ]
  End
End
