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
        #|  manifest:
        #|    applications:
        #|    - name: $app_name
        #|      buildpacks:
        #|        - binary_buildpack
        #|        - staticfile_buildpack
        #|      disk_quota: 64M
        #|      instances: 2
        #|      memory: 64M
        #|      path: $fixture/dist
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*manifest file *manifest-generated-from-pipeline.yml*"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert [ "binary_buildpack,staticfile_buildpack" == "$(test::get_app_buildpacks "$app_name" "$org" "$space")" ]
    Assert [ 64 == "$(test::get_app_disk_quota "$app_name" "$org" "$space")" ]
    Assert [ 2 == "$(test::get_app_instances "$app_name" "$org" "$space")" ]
    Assert [ 64 == "$(test::get_app_memory "$app_name" "$org" "$space")" ]
  End
End
