#!/usr/bin/env shellspec

set -euo pipefail

Describe 'auth'
  Include resource/lib/cf-functions.sh

  setup() {
    initialize_source_config_with_uaa_origin

    org=$(generate_test_name_with_spaces)

    quiet login_for_test_assertions
  }

  teardown() {
    quiet logout_for_test_assertions
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  Context 'logged in with uaa origin'
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
      The output should json '.version | keys == ["timestamp"]'
      The error should include "Creating org $org"
      Assert cf::org_exists "$org"
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
      The output should json '.version | keys == ["timestamp"]'
      The error should include "Deleting org $org"
      Assert not cf::org_exists "$org"
    End
  End
End
