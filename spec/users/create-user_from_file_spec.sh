#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

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

  It 'can create users from file'
    create_users() {
      local fixture=$(load_fixture "users")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-users-from-file
        #|  file: $fixture/users.csv
      )
      put "$config"
    }
    When call create_users
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user cfclitest-bulkload-user1"
    The error should include "Creating user cfclitest-bulkload-user2"
    The error should include "Creating user cfclitest-bulkload-user3"
    Assert cf::user_exists "cfclitest-bulkload-user1"
    Assert cf::user_exists "cfclitest-bulkload-user2"
    Assert cf::user_exists "cfclitest-bulkload-user3"
  End

  Parameters
    cfclitest-bulkload-user1
    cfclitest-bulkload-user2
    cfclitest-bulkload-user3
  End
  It "can delete user $1"
    local username=$1
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
