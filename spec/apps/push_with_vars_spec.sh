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

  It 'can push an app with vars'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|path: $fixture/dist
        #|manifest: $fixture/manifest.yml
        #|vars:
        #|  app_name: $app_name
        #|vars_files:
        #|  - $fixture/vars-memory.yml
        #|  - $fixture/vars-disk_quota.yml
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert cf::is_app_started "$app_name"
    Assert [ 96 == "$(cf::get_app_memory "$app_name")" ]
    Assert [ 100 == "$(cf::get_app_disk_quota "$app_name")" ]
  End
End
