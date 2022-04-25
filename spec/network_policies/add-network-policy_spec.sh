#!/usr/bin/env shellspec

set -euo pipefail

Describe 'services'
  Include resource/lib/cf-functions.sh

  setup() {
    source_org=$(generate_test_name_with_spaces)
    source_space=$(generate_test_name_with_spaces)
    source_app_name=$(generate_test_name_with_hyphens)

    destination_org=$(generate_test_name_with_spaces)
    destination_space=$(generate_test_name_with_spaces)
    destination_app_name=$(generate_test_name_with_hyphens)

    source=$(get_source_config) || error_and_exit "[ERROR] error loading source json config"

    test::login
    test::create_org_and_space "$source_org" "$source_space"
    test::create_org_and_space "$destination_org" "$destination_space"
  }

  teardown() {
    test::delete_org_and_space "$destination_org" "$destination_space"
    test::delete_org_and_space "$source_org" "$source_space"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  Parameters
    "source" "$source_org" "$source_space" "$source_app_name"
    "destination" "$destination_org" "$destination_space" "$destination_app_name"
  End
  It "can push the $1 app"
    local org=$2
    local space=$3
    local app_name=$4
    push_app() {
      local fixture=$(load_fixture 'static-app')
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

  It 'can add network policy'
    add_network_policy() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: add-network-policy
        #|  org: $source_org
        #|  space: $source_space
        #|  source_app: $source_app_name
        #|  destination_org: $destination_org
        #|  destination_space: $destination_space
        #|  destination_app: $destination_app_name
        #|  protocol: udp
        #|  port: 9999
      )
      put "$config"
    }
    When call add_network_policy
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Adding network policy"
    Assert test::network_policy_exists "$source_app_name" "$destination_app_name" "udp" "9999" "$source_org" "$source_space"
  End

  It 'can remove network policy'
    remove_network_policy() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: remove-network-policy
        #|  org: $source_org
        #|  space: $source_space
        #|  source_app: $source_app_name
        #|  destination_org: $destination_org
        #|  destination_space: $destination_space
        #|  destination_app: $destination_app_name
        #|  protocol: udp
        #|  port: 9999
      )
      put "$config"
    }
    When call remove_network_policy
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Removing network policy"
    Assert not test::network_policy_exists "$source_app_name" "$destination_app_name" "udp" "9999" "$source_org" "$source_space"
  End
End
