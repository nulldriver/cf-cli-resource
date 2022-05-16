#!/usr/bin/env shellspec

set -euo pipefail

Describe 'routes'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    domain="$(generate_test_name_with_hyphens).com"
    hostname=$(generate_test_name_with_hyphens)
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

  It 'can create a private domain'
    create_private_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-private-domain
        #|  domain: $domain
      )
      put "$config"
    }
    When call create_private_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating"
    Assert cf::has_private_domain "$org" "$domain"
  End

  It 'can create private domain again using deprecated command'
    create_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-domain
        #|  domain: $domain
      )
      put "$config"
    }
    When call create_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Domain $domain already exists"
    Assert cf::has_private_domain "$org" "$domain"
  End

  It 'can create a http route'
    create_http_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-route
        #|  domain: $domain
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call create_http_route
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

  It 'can map a http route'
    map_http_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: map-route
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
        #|  path: foo
      )
      if cf::is_cf8; then
        config=$(
          %text:expand
          #|$config
          #|  app_protocol: http2
        )
      fi
      put "$config"
    }
    When call map_http_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "route $hostname.$domain/foo to app $app_name"
    if cf::is_cf8; then
      The error should include "with protocol http2"
    fi
    Assert test::is_app_mapped_to_route "$app_name" "$hostname.$domain/foo" "$org" "$space"
  End

  It 'can unmap a http route'
    unmap_http_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unmap-route
        #|  domain: $domain
        #|  app_name: $app_name
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call unmap_http_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Removing route $hostname.$domain/foo from app $app_name"
    Assert not test::is_app_mapped_to_route "$app_name" "$hostname.$domain/foo" "$org" "$space"
  End

  It 'can delete a http route'
    delete_http_route() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-route
        #|  domain: $domain
        #|  hostname: $hostname
        #|  path: foo
      )
      put "$config"
    }
    When call delete_http_route
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting route $hostname.$domain/foo"
    Assert not cf::check_route "$org" "$domain" "$hostname" "foo"
  End

  It 'can delete a private domain'
    delete_private_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-private-domain
        #|  domain: $domain
      )
      put "$config"
    }
    When call delete_private_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting"
    The error should include "OK"
    Assert not cf::has_private_domain "$org" "$domain"
  End

  It 'can delete a private domain using deprecated command'
    delete_domain() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-domain
        #|  domain: $domain
      )
      put "$config"
    }
    When call delete_domain
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    if cf::is_cf6; then
      The error should include "Domain $domain not found"
    else
      The error should include "Domain '$domain' does not exist."
    fi
    Assert not cf::has_private_domain "$org" "$domain"
  End
End
