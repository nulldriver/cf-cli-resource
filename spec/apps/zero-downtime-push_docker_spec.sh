#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

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

  It 'can simple push a docker image from a private registry when current_app_name not used'
    simple_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  manifest: $fixture/manifest.yml
        #|  docker_image: $docker_image
        #|  docker_username: $docker_username
        #|  docker_password: $docker_password
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files:
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
      )
      put "$config"
    }
    When call simple_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can zero-downtime-push a docker imge from a private registry'
    zero_downtime_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  current_app_name: $app_name
        #|  manifest: $fixture/manifest.yml
        #|  docker_image: $docker_image
        #|  docker_username: $docker_username
        #|  docker_password: $docker_password
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files:
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
      )
      put "$config"
    }
    When call zero_downtime_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Renaming app"
    The error should include "Staging app"
    The error should include "Deleting app"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert not test::app_exists "$app_name-venerable" "$org" "$space"
  End
End
