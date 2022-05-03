#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    service_instance=$(generate_test_name_with_spaces)
    service_key=$(generate_test_name_with_spaces)

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

  It 'can create a service'
    create_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service
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
    Assert test::service_exists "$service_instance" "$org" "$space"
  End

  It 'can create a service key'
    create_service_key() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service-key
        #|  service_instance: $service_instance
        #|  service_key: $service_key
      )
      put "$config"
    }
    When call create_service_key
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating service key $service_key for service instance $service_instance"
    Assert test::service_key_exists "$service_instance" "$service_key" "$org" "$space"
  End

  It 'can delete a service key'
    delete_service_key() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-service-key
        #|  service_instance: $service_instance
        #|  service_key: $service_key
      )
      put "$config"
    }
    When call delete_service_key
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting key $service_key for service instance $service_instance"
    Assert not test::service_key_exists "$service_instance" "$service_key" "$org" "$space"
  End

  It 'can delete a service'
    delete_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-service
        #|  service_instance: $service_instance
      )
      put "$config"
    }
    When call delete_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting service"
    Assert not test::service_exists "$service_instance" "$org" "$space"
  End
End
