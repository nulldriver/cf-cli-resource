#!/usr/bin/env shellspec

set -euo pipefail

Describe 'buildpacks'

  setup() {
    source=$(get_source_config) || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can enable feature flag'
    enable_feature_flag() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: enable-feature-flag
        #|  feature_name: hide_marketplace_from_unauthenticated_users
      )
      put "$config"
    }
    When call enable_feature_flag
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_enabled "hide_marketplace_from_unauthenticated_users"
  End

  It 'can disable feature flag'
    disable_feature_flag() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: disable-feature-flag
        #|  feature_name: hide_marketplace_from_unauthenticated_users
      )
      put "$config"
    }
    When call disable_feature_flag
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_disabled "hide_marketplace_from_unauthenticated_users"
  End
End
