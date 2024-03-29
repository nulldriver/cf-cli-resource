#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    username=$(generate_test_name_with_hyphens)

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

  It 'can create user with password'
    create_user() {
      local password=$(generate_test_name_with_spaces)
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user
        #|  username: $username
        #|  password: $password
      )
      put "$config"
    }
    When call create_user
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user $username"
    Assert cf::user_exists "$username"
  End

  It 'can delete user with password'
    delete_user() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-user
        #|  username: $username
      )
      put "$config"
    }
    When call delete_user
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting user $username"
    Assert not cf::user_exists "$username"
  End
End
