#!/usr/bin/env shellspec

set -euo pipefail

Describe 'auth'
  Include resource/lib/cf-functions.sh

  setup() {
    initialize_source_config_for_cf_home

    cf_home=$(login_with_cf_home)
    org=$(generate_test_name_with_spaces)

    quiet login_for_test_assertions
  }

  teardown() {
    quiet logout_for_test_assertions
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  Context 'logged in with cf_home'
    It 'can create an org'
      create_org() {
        local params=$(
          %text:expand
          #|command: create-org
          #|org: $org
          #|cf_home: $cf_home
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
          #|cf_home: $cf_home
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
