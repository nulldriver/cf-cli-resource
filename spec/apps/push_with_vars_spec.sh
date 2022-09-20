#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

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

  It 'can push an app with vars'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  path: $fixture/dist
        #|  manifest: $fixture/manifest.yml
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files:
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert [ 96 == "$(test::get_app_memory "$app_name" "$org" "$space")" ]
    Assert [ 100 == "$(test::get_app_disk_quota "$app_name" "$org" "$space")" ]
  End
End
