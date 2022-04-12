#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
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

  It 'can push an app'
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

  It 'can run a task'
    run_task() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: run-task
        #|  app_name: $app_name
        #|  task_command: echo run-task-with-disk_quota-test
        #|  task_name: run-task-test
        #|  disk_quota: 128M
        #|  memory: 128M
      )
      put "$config"
    }
    When call run_task
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating task for app"
    Assert test::was_task_run "$app_name" "run-task-test"
  End
End
