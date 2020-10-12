#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh
  Include spec/apps/apps_helper.sh

  Skip if "not cf7" not cf::is_cf7

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    CCR_SOURCE=$(initialize_source_config)

    quiet create_org_and_space "$org" "$space"
    login_for_test_assertions
    quiet cf::target "$org" "$space"
  }

  teardown() {
    quiet delete_org_and_space "$org" "$space"
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can push an app using rolling strategy'
    When call push_app "$org" "$space" "$app_name" '{"strategy": "rolling", "instances": 2}'
    The status should be success
    The error should include "#0   running"
    The error should include "#1   running"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::is_app_started "$app_name"
  End
End
