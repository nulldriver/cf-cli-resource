#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    source_org=$(generate_test_name_with_spaces)
    source_space=$(generate_test_name_with_spaces)
    other_org=$(generate_test_name_with_spaces)
    other_space=$(generate_test_name_with_spaces)
    service_instance=$(generate_test_name_with_spaces)

    source=$(get_source_config) || error_and_exit "[ERROR] error loading source json config"

    test::login
    test::create_org_and_space "$source_org" "$source_space"
    test::create_org_and_space "$other_org" "$other_space"
  }

  teardown() {
    test::delete_org_and_space "$other_org" "$other_space"
    test::delete_org_and_space "$source_org" "$source_space"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can disable service instance sharing feature flag'
    disable_service_instance_sharing() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: disable-feature-flag
        #|  feature_name: service_instance_sharing
      )
      put "$config"
    }
    When call disable_service_instance_sharing
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_disabled "service_instance_sharing"
  End

  It 'can enable service instance sharing feature flag'
    enable_service_instance_sharing() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: enable-feature-flag
        #|  feature_name: service_instance_sharing
      )
      put "$config"
    }
    When call enable_service_instance_sharing
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "OK"
    Assert cf::is_feature_flag_enabled "service_instance_sharing"
  End

  It 'can create a service'
    create_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service
        #|  org: $source_org
        #|  space: $source_space
        #|  service: bookstore
        #|  plan: standard
        #|  service_instance: $service_instance
      )
      put "$config"
    }
    When call create_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating service instance $service_instance"
    Assert test::service_exists "$service_instance" "$source_org" "$source_space"
  End

  It 'can share a service'
    share_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: share-service
        #|  org: $source_org
        #|  space: $source_space
        #|  service_instance: $service_instance
        #|  other_org: $other_org
        #|  other_space: $other_space
      )
      put "$config"
    }
    When call share_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Sharing service instance $service_instance"
    Assert test::service_exists "$service_instance" "$other_org" "$other_space"
  End

  It 'can unshare a service'
    unshare_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unshare-service
        #|  org: $source_org
        #|  space: $source_space
        #|  service_instance: $service_instance
        #|  other_org: $other_org
        #|  other_space: $other_space
      )
      put "$config"
    }
    When call unshare_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Unsharing service instance $service_instance"
    Assert test::service_exists "$service_instance" "$source_org" "$source_space"
    Assert not test::service_exists "$service_instance" "$other_org" "$other_space"
  End

  It 'can delete a service'
    delete_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-service
        #|  org: $source_org
        #|  space: $source_space
        #|  service_instance: $service_instance
      )
      put "$config"
    }
    When call delete_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting service $service_instance"
    Assert not test::service_exists "$service_instance" "$source_org" "$source_space"
  End
End
