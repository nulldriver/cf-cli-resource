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

  It 'can simple push when current_app_name not used'
    simple_push() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: zero-downtime-push
        #|org: $org
        #|space: $space
        #|manifest: $fixture/manifest.yml
        #|path: $fixture/dist
        #|vars:
        #|  app_name: $app_name
        #|vars_files:
        #|  - $fixture/vars-memory.yml
        #|  - $fixture/vars-disk_quota.yml
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call simple_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert cf::is_app_started "$app_name"
  End

  It 'can zero-downtime-push'
    zero_downtime_push() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: zero-downtime-push
        #|org: $org
        #|space: $space
        #|current_app_name: $app_name
        #|manifest: $fixture/manifest.yml
        #|path: $fixture/dist
        #|vars:
        #|  app_name: $app_name
        #|vars_files:
        #|  - $fixture/vars-memory.yml
        #|  - $fixture/vars-disk_quota.yml
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call zero_downtime_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Renaming app"
    The error should include "Staging app"
    The error should include "Deleting app"
    Assert cf::is_app_started "$app_name"
  End
End
