#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

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

  It 'can create user with origin'
    create_user() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user
        #|  username: $username
        #|  origin: sso
      )
      put "$config"
    }
    When call create_user
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user $username"
    Assert cf::user_exists "$username" "sso"
  End

  It 'can delete user with origin'
    delete_user() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-user
        #|  username: $username
        #|  origin: sso
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
