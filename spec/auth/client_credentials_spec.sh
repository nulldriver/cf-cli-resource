#!/usr/bin/env shellspec

set -euo pipefail

Describe 'auth'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)

    source=$(get_source_config_with_client_credentials) || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  Context 'logged in with client credentials'
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
      The output should json '.version | keys == ["timestamp"]'
      The error should include "Creating org $org"
      Assert cf::org_exists "$org"
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
      The output should json '.version | keys == ["timestamp"]'
      The error should include "Deleting org $org"
      Assert not cf::org_exists "$org"
    End
  End
End
