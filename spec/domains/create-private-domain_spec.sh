#!/usr/bin/env shellspec

set -euo pipefail

Describe 'domains'

  setup() {
    org=$(generate_test_name_with_spaces)
    domain="$(generate_test_name_with_hyphens).com"

    source=$(get_source_config) || error_and_exit "[ERROR] error loading source json config"

    test::login
    test::create_org "$org"
  }

  teardown() {
    test::delete_org "$org"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can create a private domain'
    create_private_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-private-domain
        #|  domain: $domain
        #|  org: $org
      )
      put "$config"
    }
    When call create_private_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating"
    Assert cf::has_private_domain "$org" "$domain"
  End

  It 'can delete a private domain'
    delete_private_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-private-domain
        #|  domain: $domain
        #|  org: $org
      )
      put "$config"
    }
    When call delete_private_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting"
    The error should include "OK"
    Assert not cf::has_private_domain "$org" "$domain"
  End
End
