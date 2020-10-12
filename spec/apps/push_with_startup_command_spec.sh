#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh
  Include spec/apps/apps_helper.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)
    startup_command='$HOME/boot.sh --dummy-flag'

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

  It 'can push an app with custom startup command'
    When call push_app "$org" "$space" "$app_name" "$(jq -n --arg startup_command "$startup_command" '{startup_command: $startup_command}')"
    The status should be success
    The error should include "#0   running"
    The output should json '.version | keys == ["timestamp"]'
    Assert [ "$startup_command" == "$(cf::get_app_startup_command "$app_name")" ]
  End

  It 'can push an app reset to default startup command'
    When call push_app "$org" "$space" "$app_name" "$(jq -n --arg startup_command "null" '{startup_command: $startup_command}')"
    The status should be success
    The error should include "#0   running"
    The output should json '.version | keys == ["timestamp"]'
    Assert [ "$startup_command" != "$(cf::get_app_startup_command "$app_name")" ]
  End
End
