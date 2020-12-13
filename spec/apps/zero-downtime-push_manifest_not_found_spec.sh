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

  It 'can error if manifest not found'
    push_with_invalid_manifest() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: zero-downtime-push
        #|manifest: $fixture/does_not_exist.yml
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_with_invalid_manifest
    The status should eq $E_MANIFEST_FILE_NOT_FOUND
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*invalid payload (manifest is not a file: */does_not_exist.yml*)"
  End
End
