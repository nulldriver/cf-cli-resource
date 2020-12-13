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

  It 'can push an app'
    push_app() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|buildpacks:
        #|  - binary_buildpack
        #|  - staticfile_buildpack
        #|disk_quota: 64M
        #|instances: 2
        #|memory: 64M
        #|path: $fixture/dist
        #|no_start: true
        #|staging_timeout: 15
        #|startup_timeout: 5
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert [ "binary_buildpack,staticfile_buildpack" == "$(cf::get_app_buildpacks "$app_name")" ]
    Assert [ 64 == "$(cf::get_app_disk_quota "$app_name")" ]
    Assert [ 2 == "$(cf::get_app_instances "$app_name")" ]
    Assert [ 64 == "$(cf::get_app_memory "$app_name")" ]
    Assert cf::is_app_stopped "$app_name"
    # TODO: Are staging_timeout and startup_timeout testable?
  End

  It 'can push an app with deprecated buildpack param'
    push_app_with_deprecated_buildpack_param() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|path: $fixture/dist
        #|no_start: true
        #|disk_quota: 256M
        #|memory: 64M
        #|buildpack: php_buildpack
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push_app_with_deprecated_buildpack_param
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert cf::is_app_stopped "$app_name"
    Assert [ "php_buildpack" == "$(cf::get_app_buildpacks "$app_name")" ]
  End
End
