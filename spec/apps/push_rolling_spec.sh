#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  Skip if "not cf7" not cf::is_cf7

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

  It 'can push an app'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $fixture/dist
        #|memory: 64M
        #|disk_quota: 64M
        #|instances: 2
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert cf::is_app_started "$app_name"
  End

  It 'can push an app using rolling strategy'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $fixture/dist
        #|memory: 64M
        #|disk_quota: 64M
        #|instances: 2
        #|strategy: rolling
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert cf::is_app_started "$app_name"
    # TODO: how do we test that the strategy actually worked?
  End
End
