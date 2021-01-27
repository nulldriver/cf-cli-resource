#!/usr/bin/env shellspec

set -euo pipefail

Describe 'routes'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    domain="$(generate_test_name_with_hyphens).com"
    hostname=$(generate_test_name_with_hyphens)
    app_name=$(generate_test_name_with_hyphens)
    source=$(
      %text:expand
      #|source:
      #|  api: $CCR_CF_API
      #|  username: $CCR_CF_USERNAME
      #|  password: $CCR_CF_PASSWORD
      #|  cf_cli_version: $CCR_CF_CLI_VERSION
    )

    test::login
    test::create_org "$org"
    test::create_space "$org" "$space"
  }

  teardown() {
    test::delete_org "$org"
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can create private domain'
    create_domain() {      
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-domain
        #|  org: $org
        #|  domain: $domain
      )
      put "$config"
    }
    When call create_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating"
    The error should include "OK"
    Assert cf::has_private_domain "$org" "$domain"
  End

  It 'can create a route'
    create_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
      )
      put "$config"
    }
    When call create_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating route $domain"
    The error should include "Route $domain has been created."
    Assert cf::check_route "$org" "$domain"
  End

  It 'can create a route with hostname'
    create_route_with_hostname() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  hostname: $hostname
      )
      put "$config"
    }
    When call create_route_with_hostname
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating route $hostname.$domain"
    The error should include "Route $hostname.$domain has been created."
    Assert cf::check_route "$org" "$domain" "$hostname"
  End

  It 'can create a route with hostname and path'
    create_route_with_hostname_and_path() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call create_route_with_hostname_and_path
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating route $hostname.$domain/foo"
    The error should include "Route $hostname.$domain/foo has been created."
    Assert cf::check_route "$org" "$domain" "$hostname" "foo"
  End

  It 'can push an app for route tests'
    push_app() {
      local fixture=$(load_fixture "static-app")
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

  It 'can map a route'
    map_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: map-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
      )
      put "$config"
    }
    When call map_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "route $domain to app $app_name"
    Assert test::is_app_mapped_to_route "$app_name" "$domain" "$org" "$space"
  End

  It 'can map a route with hostname'
    map_route_with_hostname() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: map-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
      )
      put "$config"
    }
    When call map_route_with_hostname
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "route $hostname.$domain to app $app_name"
    Assert test::is_app_mapped_to_route "$app_name" "$hostname.$domain" "$org" "$space"
  End

  It 'can map a route with hostname and path'
    map_route_with_hostname_and_path() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: map-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call map_route_with_hostname_and_path
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "route $hostname.$domain/foo to app $app_name"
    Assert test::is_app_mapped_to_route "$app_name" "$hostname.$domain/foo" "$org" "$space"
  End

  It 'can unmap a route with hostname and path'
    unmap_route_with_hostname_and_path() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unmap-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call unmap_route_with_hostname_and_path
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Removing route $hostname.$domain/foo from app $app_name"
    Assert not test::is_app_mapped_to_route "$app_name" "$hostname.$domain/foo" "$org" "$space"
  End

  It 'can unmap a route with hostname'
    unmap_route_with_hostname() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unmap-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
      )
      put "$config"
    }
    When call unmap_route_with_hostname
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Removing route $hostname.$domain from app $app_name"
    Assert not test::is_app_mapped_to_route "$app_name" "$hostname.$domain" "$org" "$space"
  End

  It 'can unmap a route'
    unmap_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unmap-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  app_name: $app_name
      )
      put "$config"
    }
    When call unmap_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Removing route $domain from app $app_name"
    Assert not test::is_app_mapped_to_route "$app_name" "$domain" "$org" "$space"
  End

  It 'can delete a route with hostname and path'
    delete_route_with_hostname_and_path() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call delete_route_with_hostname_and_path
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting route $hostname.$domain/foo"
    Assert not cf::check_route "$org" "$domain" "$hostname" "foo"
  End

  It 'can delete a route with hostname'
    delete_route_with_hostname() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  hostname: $hostname
      )
      put "$config"
    }
    When call delete_route_with_hostname
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting route $hostname.$domain"
    Assert not cf::check_route "$org" "$domain" "$hostname"
  End

  It 'can delete a route'
    delete_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-route
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
      )
      put "$config"
    }
    When call delete_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting route $domain"
    Assert not cf::check_route "$org" "$domain"
  End

  It 'can delete private domain'
    delete_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-domain
        #|  org: $org
        #|  domain: $domain
      )
      put "$config"
    }
    When call delete_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting"
    The error should include "OK"
    Assert not cf::has_private_domain "$org" "$domain"
  End
End
