#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    docker_image=$(get_env_var "CCR_DOCKER_PRIVATE_IMAGE") || error_and_exit "[ERROR] required env var not set: CCR_DOCKER_PRIVATE_IMAGE"
    docker_username=$(get_env_var "CCR_DOCKER_PRIVATE_USERNAME") || error_and_exit "[ERROR] required env var not set: CCR_DOCKER_PRIVATE_USERNAME"
    docker_password=$(get_env_var "CCR_DOCKER_PRIVATE_PASSWORD") || error_and_exit "[ERROR] required env var not set: CCR_DOCKER_PRIVATE_PASSWORD"

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

  It 'can disable docker feature flag'
    disable_docker() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: disable-feature-flag
        #|  feature_name: diego_docker
      )
      put "$config"
    }
    When call disable_docker
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_disabled "diego_docker"
  End

  It 'can enable docker feature flag'
    enable_docker() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: enable-feature-flag
        #|  feature_name: diego_docker
      )
      put "$config"
    }
    When call enable_docker
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_enabled "diego_docker"
  End

  It 'can push a docker image from a private registry'
    push() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  org: $org
        #|  space: $space
        #|  app_name: $app_name
        #|  memory: 64M
        #|  disk_quota: 64M
        #|  docker_image: $docker_image
        #|  docker_username: $docker_username
        #|  docker_password: $docker_password
      )
      put "$config"
    }
    When call push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Using docker repository password from environment variable CF_DOCKER_PASSWORD"
    The error should include "Staging app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End
End
