#!/usr/bin/env shellspec

set -euo pipefail

Describe 'buildpacks'

  setup() {
    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    buildpack=$(generate_test_name_with_hyphens)

    source=$(get_source_config) || error_and_exit "[ERROR] error loading source json config"

    test::login
  }

  teardown() {
    test::logout
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can create a buildpack'
    create_buildpack() {
      local fixture=$(load_fixture 'buildpack')
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: create-buildpack
        #|  buildpack: $buildpack
        #|  path: $fixture
        #|  position: 99
        #|  enabled: false
      )
      put "$config"
    }
    When call create_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Creating buildpack"
    Assert cf::has_buildpack "$buildpack"
    Assert not cf::is_buildpack_enabled "$buildpack"
  End

  It 'can assign a stack'
    assign_stack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  assign_stack: cflinuxfs3
      )
      put "$config"
    }
    When call assign_stack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Assigning stack"
    Assert [ "cflinuxfs3" == "$(cf::get_buildpack_stack "$buildpack")" ]
  End

  It 'can update a buildpack path'
    local original_path=$(cf::get_buildpack_filename "$buildpack")
    update_path() {
      local fixture=$(load_fixture 'buildpack')
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  path: $fixture
      )
      put "$config"
    }
    When call update_path
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Uploading buildpack"
    Assert [ "$original_path" != "$(cf::get_buildpack_filename "$buildpack")" ]
  End

  It 'can enable a buildpack'
    enable_buildpack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  enabled: true
      )
      put "$config"
    }
    When call enable_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating buildpack"
    Assert cf::is_buildpack_enabled "$buildpack"
  End

  It 'can disable a buildpack'
    disable_buildpack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  enabled: false
      )
      put "$config"
    }
    When call disable_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating buildpack"
    Assert not cf::is_buildpack_enabled "$buildpack"
  End

  It 'can lock a buildpack'
    lock_buildpack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  locked: true
      )
      put "$config"
    }
    When call lock_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating buildpack"
    Assert cf::is_buildpack_locked "$buildpack"
  End

  It 'can unlock a buildpack'
    unlock_buildpack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  locked: false
      )
      put "$config"
    }
    When call unlock_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating buildpack"
    Assert not cf::is_buildpack_locked "$buildpack"
  End

  It 'can update a buildpack position'
    local current_position=$(cf::get_buildpack_position "$buildpack")
    local new_position=$(($current_position - 1))
    update_position() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: update-buildpack
        #|  buildpack: $buildpack
        #|  position: $new_position
      )
      put "$config"
    }
    When call update_position
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Updating buildpack"
    Assert [ "$new_position" == "$(cf::get_buildpack_position "$buildpack")" ]
  End

  It 'can delete a buildpack'
    delete_buildpack() {
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: delete-buildpack
        #|  buildpack: $buildpack
        #|  stack: cflinuxfs3
      )
      put "$config"
    }
    When call delete_buildpack
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Deleting buildpack"
    Assert not cf::has_buildpack "$buildpack"
  End
End
