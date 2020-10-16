#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    CCR_SOURCE=$(initialize_source_config)

    quiet create_org_and_space "$org" "$space"
    login_for_test_assertions
    quiet cf::target "$org" "$space"
  }

  teardown() {
    quiet delete_org_and_space "$org" "$space"
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
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $fixture/dist
        #|memory: 64M
        #|disk_quota: 64M
        #|stack: windows
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app_with_windows_stack
    The status should be failure
    The error should include "Found no compatible cell"
    The output should json '.version | keys == ["timestamp"]'
    Assert [ "windows" == "$(cf::get_app_stack "$app_name")" ]
  End
End
