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
        #|instances: 1
        #|memory: 64M
        #|disk_quota: 64M
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert cf::is_app_started "$app_name"
  End

  It 'can scale disk_quota'
    scale_disk_quota() {
      local params=$(
        %text:expand
        #|command: scale
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|disk_quota: 100M
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call scale_disk_quota
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 100 == "$(cf::get_app_disk_quota "$app_name")" ]
  End

  It 'can scale memory'
    scale_memory() {
      local params=$(
        %text:expand
        #|command: scale
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|memory: 96M
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call scale_memory
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 96 == "$(cf::get_app_memory "$app_name")" ]
  End

  It 'can scale instances'
    scale_instances() {
      local params=$(
        %text:expand
        #|command: scale
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|instances: 2
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call scale_instances
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 2 == "$(cf::get_app_instances "$app_name")" ]
  End
End
