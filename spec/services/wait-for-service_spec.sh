#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    service_instance=$(generate_test_name_with_spaces)

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

  It 'can create an asynchronous service without waiting'
    create_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service
        #|  service: bookstore-async
        #|  plan: standard
        #|  service_instance: $service_instance
        #|  broker: bookstore-async
        #|  configuration: '{"ram_gb":4}'
        #|  tags: list, of, tags
      )
      put "$config"
    }
    When call create_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating service instance $service_instance"
    Assert test::service_exists "$service_instance" "$org" "$space"
    Assert [ "standard" == "$(test::get_service_instance_plan "$service_instance" "$org" "$space")" ]
    Assert [ "list, of, tags" == "$(test::get_service_instance_tags "$service_instance" "$org" "$space")" ]
  End

  It 'can wait for asynchronous service'
    wait_for_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: wait-for-service
        #|  service_instance: $service_instance
      )
      put "$config"
    }
    When call wait_for_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*Waiting for service: *$service_instance*"
    The error should match pattern "*Service is ready: *$service_instance*"
    Assert test::service_exists "$service_instance" "$org" "$space"
  End

  It 'can update an asynchronous service and wait'
    create_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-service
        #|  service: bookstore-async
        #|  plan: pro
        #|  service_instance: $service_instance
        #|  broker: bookstore-async
        #|  configuration: '{"ram_gb":8}'
        #|  tags: some, other, tags
        #|  update_service: true
        #|  wait_for_service: true
      )
      put "$config"
    }
    When call create_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating service instance $service_instance"
    The error should match pattern "*Waiting for service: *$service_instance*"
    The error should match pattern "*Service is ready: *$service_instance*"
    Assert test::service_exists "$service_instance" "$org" "$space"
    Assert [ "pro" == "$(test::get_service_instance_plan "$service_instance" "$org" "$space")" ]
    Assert [ "some, other, tags" == "$(test::get_service_instance_tags "$service_instance" "$org" "$space")" ]
  End

  It 'can delete a service'
    delete_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-service
        #|  service_instance: $service_instance
        #|  wait_for_service: true
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
