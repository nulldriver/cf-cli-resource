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
        #|  app_name: $app_name
        #|  buildpacks:
        #|    - binary_buildpack
        #|    - staticfile_buildpack
        #|  disk_quota: 64M
        #|  instances: 2
        #|  memory: 64M
        #|  path: $fixture/dist
        #|  no_start: true
        #|  staging_timeout: 15
        #|  startup_timeout: 5
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert [ "binary_buildpack,staticfile_buildpack" == "$(test::get_app_buildpacks "$app_name" "$org" "$space")" ]
    Assert [ 64 == "$(test::get_app_disk_quota "$app_name" "$org" "$space")" ]
    Assert [ 2 == "$(test::get_app_instances "$app_name" "$org" "$space")" ]
    Assert [ 64 == "$(test::get_app_memory "$app_name" "$org" "$space")" ]
    Assert test::is_app_stopped "$app_name" "$org" "$space"
    # TODO: Are staging_timeout and startup_timeout testable?
  End

  It 'can push an app with deprecated buildpack param'
    push_app_with_deprecated_buildpack_param() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  app_name: $app_name
        #|  path: $fixture/dist
        #|  no_start: true
        #|  disk_quota: 256M
        #|  memory: 64M
        #|  buildpack: php_buildpack
      )
      put "$config"
    }
    When call push_app_with_deprecated_buildpack_param
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_stopped "$app_name" "$org" "$space"
    Assert [ "php_buildpack" == "$(test::get_app_buildpacks "$app_name" "$org" "$space")" ]
  End
End
