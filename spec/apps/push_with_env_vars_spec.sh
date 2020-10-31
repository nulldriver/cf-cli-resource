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

  It 'can push an app with environment variables and without manifest'
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
        #|environment_variables:
        #|  KEY1: value 1
        #|  KEY2: another value
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*manifest file *manifest-generated-for-environment-variables.yml*"
    Assert cf::is_app_started "$app_name"
    Assert cf::has_env "$app_name" "KEY1" "value 1"
    Assert cf::has_env "$app_name" "KEY2" "another value"
  End

  It 'can push an app with environment variables and with manifest'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|manifest: $fixture/manifest.yml
        #|path: $fixture/dist
        #|vars:
        #|  app_name: $app_name
        #|  memory: 64M
        #|  disk_quota: 64M
        #|environment_variables:
        #|  KEY1: value 1
        #|  KEY2: another value
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*manifest file *manifest-modified-with-environment-variables.yml*"
    Assert cf::is_app_started "$app_name"
    Assert cf::has_env "$app_name" "EXISTING_MANIFEST_ENV_VAR" "existing value"
    Assert cf::has_env "$app_name" "KEY1" "value 1"
    Assert cf::has_env "$app_name" "KEY2" "another value"
  End
End
