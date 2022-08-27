#!/usr/bin/env shellspec

set -euo pipefail

Describe 'domains'

  setup() {
    org=$(generate_test_name_with_spaces)
    shared_domain="$(generate_test_name_with_hyphens).com"
    internal_domain="$(generate_test_name_with_hyphens).internal.cfclitest"

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

  It 'can create a shared domain'
    create_shared_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-shared-domain
        #|  domain: $shared_domain
      )
      put "$config"
    }
    When call create_shared_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating"
    Assert cf::has_shared_domain "$shared_domain"
  End

  It 'can delete a shared domain'
    delete_shared_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-shared-domain
        #|  domain: $shared_domain
        #|  org: $org
      )
      put "$config"
    }
    When call delete_shared_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting"
    The error should include "OK"
    Assert not cf::has_shared_domain "$shared_domain"
  End

  It 'can create an internal domain'
    create_internal_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-shared-domain
        #|  domain: $internal_domain
        #|  internal: true
      )
      put "$config"
    }
    When call create_internal_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating"
    Assert cf::has_shared_domain "$internal_domain"
  End

  It 'can delete an internal domain'
    delete_internal_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-shared-domain
        #|  domain: $internal_domain
        #|  org: $org
      )
      put "$config"
    }
    When call delete_internal_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting"
    The error should include "OK"
    Assert not cf::has_shared_domain "$internal_domain"
  End
End
