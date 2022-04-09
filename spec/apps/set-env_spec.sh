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

  It 'can set-env on app'
    set_env() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: set-env
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  environment_variables:
        #|    KEY1: some value
        #|    KEY2: some other value
      )
      put "$config"
    }
    When call set_env
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Setting env variable"
    Assert test::has_env "$app_name" "KEY1" "some value" "$org" "$space"
    Assert test::has_env "$app_name" "KEY2" "some other value" "$org" "$space"
  End

  It 'can set-env on app using deprecated params'
    set_env_using_deprecated_params() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: set-env
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  env_var_name: KEY3
        #|  env_var_value: yet another value
      )
      put "$config"
    }
    When call set_env_using_deprecated_params
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Setting env variable"
    Assert test::has_env "$app_name" "KEY3" "yet another value" "$org" "$space"
  End
End
