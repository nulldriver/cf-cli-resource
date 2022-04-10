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

  It 'can push an app with environment variables and without manifest'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  memory: 64M
        #|  disk_quota: 64M
        #|  environment_variables:
        #|    KEY1: value 1
        #|    KEY2: another value
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*manifest file *manifest-generated-for-environment-variables.yml*"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert test::has_env "$app_name" "KEY1" "value 1" "$org" "$space"
    Assert test::has_env "$app_name" "KEY2" "another value" "$org" "$space"
  End

  It 'can push an app with environment variables and with manifest'
    fixture=$(load_fixture "static-app")
    push_app() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  manifest: $fixture/manifest.yml
        #|  path: $fixture/dist
        #|  vars:
        #|    app_name: $app_name
        #|    memory: 64M
        #|    disk_quota: 64M
        #|  environment_variables:
        #|    KEY1: value 1
        #|    KEY2: another value
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "environment_variables: backing up original manifest to: $fixture/manifest.yml.bak"
    The error should include "environment_variables: adding env to manifest: $fixture/manifest.yml"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert test::has_env "$app_name" "EXISTING_MANIFEST_ENV_VAR" "existing value" "$org" "$space"
    Assert test::has_env "$app_name" "KEY1" "value 1" "$org" "$space"
    Assert test::has_env "$app_name" "KEY2" "another value" "$org" "$space"
  End
End
