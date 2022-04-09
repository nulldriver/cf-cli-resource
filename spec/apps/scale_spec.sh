#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    source=$(get_source_config "$org" "$space") || error_and_exit "[ERROR] error loading source json config"

    test::login
    test::create_org_and_space "$org" "$space"
  }

  teardown() {
    test::delete_org_and_space "$org" "$space"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can push an app'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  instances: 1
        #|  memory: 64M
        #|  disk_quota: 64M
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can scale disk_quota'
    scale_disk_quota() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: scale
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  disk_quota: 100M
      )
      put "$config"
    }
    When call scale_disk_quota
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 100 == "$(test::get_app_disk_quota "$app_name" "$org" "$space")" ]
  End

  It 'can scale memory'
    scale_memory() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: scale
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  memory: 96M
      )
      put "$config"
    }
    When call scale_memory
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 96 == "$(test::get_app_memory "$app_name" "$org" "$space")" ]
  End

  It 'can scale instances'
    scale_instances() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: scale
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  instances: 2
      )
      put "$config"
    }
    When call scale_instances
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Scaling app"
    Assert [ 2 == "$(test::get_app_instances "$app_name" "$org" "$space")" ]
  End
End
