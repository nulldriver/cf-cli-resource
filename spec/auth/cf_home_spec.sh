#!/usr/bin/env shellspec

set -euo pipefail

Describe 'auth'

  setup() {
    cf_home=$(login_with_cf_home)
    org=$(generate_test_name_with_spaces)

    source=$(get_source_config_for_cf_home) || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  Context 'logged in with cf_home'
    It 'can create an org'
      create_org() {
        local config=$(
          %text:expand
          #|$source
          #|params:
          #|  command: create-org
          #|  org: $org
          #|  cf_home: $cf_home
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
          #|  cf_home: $cf_home
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
