#!/usr/bin/env shellspec

set -euo pipefail

Describe 'config'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    fixture=$(load_fixture "command_files")

    source=$(get_source_config "$org" "$space") || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It can 'create an org and space with command_file'
    create_org_and_space_with_command_file() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: does-not-exist
        #|  command_file: $fixture/create-org-and-space.yml
      )
      put "$config"
    }
    When call create_org_and_space_with_command_file
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating org $org"
    The error should include "Creating space $space in org $org"
    Assert cf::org_exists "$org"
    Assert cf::space_exists "$org" "$space"
  End

  It can 'delete an org with command_file'
    delete_org_with_command_file() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: does-not-exist
        #|  command_file: $fixture/delete-org.yml
      )
      put "$config"
    }
    When call delete_org_with_command_file
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting org $org"
    Assert not cf::space_exists "$org" "$space"
    Assert not cf::org_exists "$org"
  End
End
