#!/usr/bin/env shellspec

set -euo pipefail

Describe 'ssh'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)

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

  It 'can disallow space ssh'
    disallow_space_ssh() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: disallow-space-ssh
        #|  space: $space
      )
      put "$config"
    }
    When call disallow_space_ssh
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Disabling ssh support for space"
    Assert not test::is_space_ssh_allowed "$org" "$space"
  End

  It 'can allow space ssh'
    allow_space_ssh() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: allow-space-ssh
        #|  space: $space
      )
      put "$config"
    }
    When call allow_space_ssh
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Enabling ssh support for space"
    Assert test::is_space_ssh_allowed "$org" "$space"
  End
End
