#!/usr/bin/env shellspec

set -euo pipefail

Describe 'orgs and spaces'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)

    source=$(get_source_config "$org" "$space") || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'

  It 'can create an org'
    create_org() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-org
        #|  org: $org
      )
      put "$config"
    }
    When call create_org
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\"' to target new org"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::org_exists "$org"
  End

  It 'can create a space'
    create_space() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-space
        #|  org: $org
        #|  space: $space
      )
      put "$config"
    }
    When call create_space
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\" -s \"$space\"' to target new space"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::space_exists "$org" "$space"
  End

  It 'can delete a space'
    delete_space() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-space
        #|  org: $org
        #|  space: $space
      )
      put "$config"
    }
    When call delete_space
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::space_exists "$org" "$space"
  End

  It 'can delete an org'
    delete_org() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-org
        #|  org: $org
      )
      put "$config"
    }
    When call delete_org
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::org_exists "$org"
  End
End
