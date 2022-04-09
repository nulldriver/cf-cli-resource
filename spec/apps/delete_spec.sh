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

  It 'can delete an app'
    delete_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  delete_mapped_routes: true
      )
      put "$config"
    }
    When call delete_app "$org" "$space" "$app_name"
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting app"
    Assert not test::app_exists "$app_name"  "$org" "$space"
  End
End
