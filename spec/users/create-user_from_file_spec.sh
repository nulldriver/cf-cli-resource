#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    uuid=$(generate_unique_id)

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
      uuid=$uuid org=$org space=$space envsubst < $fixture/users-template.csv > $fixture/users.csv
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
    The error should include "Creating user cfclitest-$uuid-1"
    The error should include "Creating user cfclitest-$uuid-2"
    The error should include "Creating user cfclitest-$uuid-3"
    Assert cf::user_exists "cfclitest-$uuid-1"
    Assert cf::user_exists "cfclitest-$uuid-2"
    Assert cf::user_exists "cfclitest-$uuid-3"
  End

  Parameters
    cfclitest-$uuid-1
    cfclitest-$uuid-2
    cfclitest-$uuid-3
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
