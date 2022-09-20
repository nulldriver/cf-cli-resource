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

  It 'can simple push when current_app_name not used'
    simple_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  manifest: $fixture/manifest.yml
        #|  path: $fixture/dist
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files:
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
        #|  no_start: true
      )
      put "$config"
    }
    When call simple_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "requested state:   stopped"
    Assert not test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can zero-downtime-push'
    zero_downtime_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  current_app_name: $app_name
        #|  manifest: $fixture/manifest.yml
        #|  path: $fixture/dist
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files:
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
        #|  no_start: true
      )
      put "$config"
    }
    When call zero_downtime_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Renaming app"
    The error should include "requested state:   stopped"
    The error should include "Deleting app"
    Assert not test::is_app_started "$app_name" "$org" "$space"
    Assert not test::app_exists "$app_name-venerable" "$org" "$space"
  End
End
