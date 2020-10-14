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
    push_app_with_vars() {
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|manifest: $FIXTURE/static-app/manifest.yml
        #|vars:
        #|  app_name: $app_name
        #|vars_files:
        #|  - $FIXTURE/static-app/vars-memory.yml
        #|  - $FIXTURE/static-app/vars-disk_quota.yml
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app_with_vars
    The status should be success
    The error should include "#0   running"
    The output should json '.version | keys == ["timestamp"]'
    Assert cf::is_app_started "$app_name"
    Assert [ 96 == "$(cf::get_app_memory "$app_name")" ]
    Assert [ 100 == "$(cf::get_app_disk_quota "$app_name")" ]
  End
End
