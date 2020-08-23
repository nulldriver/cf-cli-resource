#!/usr/bin/env shellspec

set -euo pipefail

Describe 'orgs and spaces'
  Include resource/lib/cf-functions.sh
  Include spec/orgs/orgs_helper.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    CCR_SOURCE=$(initialize_source_config)
    login_for_test_assertions
  }

  BeforeAll 'setup'

  It 'can create an org'
    When call create_org "$org"
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\"' to target new org"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::org_exists "$org"
  End

  It 'can create a space'
    When call create_space "$org" "$space"
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\" -s \"$space\"' to target new space"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::space_exists "$org" "$space"
  End

  It 'can delete a space'
    When call delete_space "$org" "$space"
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::space_exists "$org" "$space"
  End

  It 'can delete an org'
    When call delete_org "$org"
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::org_exists "$org"
  End
End
