#!/usr/bin/env shellspec

set -euo pipefail

Describe 'orgs and spaces'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    CCR_SOURCE=$(initialize_source_config)
    login_for_test_assertions
  }

  BeforeAll 'setup'

  It 'can create an org'
    create_org() {
      local params=$(
        %text:expand
        #|command: create-org
        #|org: $org
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call create_org
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\"' to target new org"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::org_exists "$org"
  End

  It 'can create a space'
    create_space() {
      local params=$(
        %text:expand
        #|command: create-space
        #|org: $org
        #|space: $space
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call create_space
    The status should be success
    The error should end with "TIP: Use 'cf target -o \"$org\" -s \"$space\"' to target new space"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::space_exists "$org" "$space"
  End

  It 'can delete a space'
    delete_space() {
      local params=$(
        %text:expand
        #|command: delete-space
        #|org: $org
        #|space: $space
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call delete_space
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::space_exists "$org" "$space"
  End

  It 'can delete an org'
    delete_org() {
      local params=$(
        %text:expand
        #|command: delete-org
        #|org: $org
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call delete_org
    The status should be success
    The error should end with "OK"
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::org_exists "$org"
  End
End
