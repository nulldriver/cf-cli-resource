#!/usr/bin/env shellspec

set -euo pipefail

Describe 'routes'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    domain=$CCR_CF_APPS_DOMAIN
    route_service_app_name=$(generate_test_name_with_hyphens)
    route_service_app_hostname=$(app_to_hostname "$route_service_app_name")
    app_name=$(generate_test_name_with_hyphens)
    app_hostname=$(app_to_hostname "$app_name")
    source=$(
      %text:expand
      #|source:
      #|  api: $CCR_CF_API
      #|  username: $CCR_CF_USERNAME
      #|  password: $CCR_CF_PASSWORD
      #|  cf_cli_version: ${CCR_CF_CLI_VERSION:-$DEFAULT_CF_CLI_VERSION}
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
#   AfterAll 'teardown'

  It 'can push a route service app'
    push_app() {
      local fixture=$(load_fixture "logging-route-service")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: push
        #|  org: $org
        #|  space: $space
        #|  app_name: $route_service_app_name
        #|  path: $fixture
        #|  manifest: $fixture/manifest.yml
        #|  memory: 64M
        #|  disk_quota: 64M
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should match pattern "*manifest file *manifest.yml*"
    Assert test::is_app_started "$route_service_app_name" "$org" "$space"
  End

  It 'can create a route service'
    create_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-user-provided-service
        #|  org: $org
        #|  space: $space
        #|  service_instance: my_route_service
        #|  route_service_url: "https://$route_service_app_hostname.$domain"
      )
      put "$config"
    }
    When call create_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating user provided service"
    Assert test::service_exists "my_route_service"  "$org" "$space"
  End

  It 'can push an app for route service tests'
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
        #|  manifest:
        #|    applications:
        #|    - routes:
        #|      - route: $app_hostname.$domain
        #|      - route: $app_hostname.$domain/foo
      )
      put "$config"
    }
    When call push_app
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Pushing app"
    Assert test::is_app_started "$app_name" "$org" "$space"
  End

  It 'can bind a route service to an app'
    bind_route_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: bind-route-service
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  service_instance: my_route_service
        #|  hostname: $app_hostname
        #|  path: foo
        #|  configuration: {}
      )
      put "$config"
    }
    When call bind_route_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Binding route"
    Assert test::is_app_bound_to_route_service "$app_name" "my_route_service" "$org" "$space" "/foo"
  End

  It 'can unbind a route service to an app'
    unbind_route_service() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: unbind-route-service
        #|  org: $org
        #|  space: $space
        #|  domain: $domain
        #|  service_instance: my_route_service
        #|  hostname: $app_hostname
        #|  path: foo
      )
      put "$config"
    }
    When call unbind_route_service
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Unbinding route"
    Assert not test::is_app_bound_to_route_service "$app_name" "my_route_service" "$org" "$space" "/foo"
  End

End
