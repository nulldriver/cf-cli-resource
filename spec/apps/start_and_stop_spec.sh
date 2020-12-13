#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    initialize_source_config

    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    quiet create_org_and_space "$org" "$space"
    quiet login_for_test_assertions "$org" "$space"
  }

  teardown() {
    quiet delete_org_and_space "$org" "$space"
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can push an app without starting'
    push_app_no_start() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $fixture/dist
        #|disk_quota: 64M
        #|memory: 64M
        #|no_start: true
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app_no_start
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert cf::is_app_stopped "$app_name"
  End

  It 'can start an app'
    start_app() {
      local params=$(
        %text:expand
        #|command: start
        #|org: $org
        #|space: $space
        #|app_name: $app_name
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call start_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Starting app"
    Assert cf::is_app_started "$app_name"
  End

  It 'can stop an app'
    stop_app() {
      local params=$(
        %text:expand
        #|command: stop
        #|org: $org
        #|space: $space
        #|app_name: $app_name
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call stop_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Stopping app"
    Assert cf::is_app_stopped "$app_name"
  End
End
