#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

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

  It 'can show logs on a failed push'
    push_app() {
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $FIXTURE/static-app/dist
        #|disk_quota: 1M
        #|show_app_log: true
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should eq $E_PUSH_FAILED_WITH_APP_LOGS_SHOWN
    The error should include "Retrieving logs for app $app_name in org $org / space $space as $(echo $CCR_SOURCE | jq -r .source.username)..."
    The output should json '.version | keys == ["timestamp"]'
    Assert not cf::is_app_started "$app_name"
  End
End
