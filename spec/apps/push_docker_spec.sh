#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    initialize_source_config
    initialize_docker_config

    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    quiet create_org_and_space "$org" "$space"
    quiet login_for_test_assertions "$org" "$space"
  }

  teardown() {
    quiet delete_org_and_space "$org" "$space"
    quiet logout_for_test_assertions
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can disable docker feature flag'
    disable_docker() {
      local params=$(
        %text:expand
        #|command: disable-feature-flag
        #|feature_name: diego_docker
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call disable_docker
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Feature diego_docker Disabled"
    Assert cf::is_feature_flag_disabled "diego_docker"
  End

  It 'can enable docker feature flag'
    enable_docker() {
      local params=$(
        %text:expand
        #|command: enable-feature-flag
        #|feature_name: diego_docker
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call enable_docker
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Feature diego_docker Enabled"
    Assert cf::is_feature_flag_enabled "diego_docker"
  End

  It 'can push a docker image from a private registry'
    push() {
      local params=$(
        %text:expand
        #|command: push
        #|org: $org
        #|space: $space
        #|app_name: $app_name
        #|memory: 64M
        #|disk_quota: 64M
        #|docker_image: $CCR_DOCKER_PRIVATE_IMAGE
        #|docker_username: $CCR_DOCKER_PRIVATE_USERNAME
        #|docker_password: $CCR_DOCKER_PRIVATE_PASSWORD
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Using docker repository password from environment variable CF_DOCKER_PASSWORD"
    The error should include "Staging app"
    Assert cf::is_app_started "$app_name"
  End
End
