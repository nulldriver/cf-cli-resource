#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'

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

  It 'can simple push when current_app_name not used'
    simple_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  manifest: $fixture/manifest.yml
        #|  path: $fixture/dist
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files: 
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
        #|  environment_variables:
        #|    NEW_ENV_VAR: new env var
      )
      put "$config"
    }
    When call simple_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert test::is_app_started "$app_name" "$org" "$space"
    Assert [ "$(test::get_env "$app_name" "NEW_ENV_VAR" "$org" "$space")" == "new env var" ]
    Assert [ "$(test::get_env "$app_name" "EXISTING_MANIFEST_ENV_VAR" "$org" "$space")" == "existing value" ]
    Assert [ "$(test::get_env "$app_name" "SINGLE_QUOTED" "$org" "$space")" == "Several lines of text, containing 'single quotes'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(test::get_env "$app_name" "DOUBLE_QUOTED" "$org" "$space")" == "Several lines of text, containing \"double quotes\". Escapes (like \n) work.
In addition, newlines can be escaped to prevent them from being converted to a space.
Newlines can also be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(test::get_env "$app_name" "PLAIN" "$org" "$space")" == "Several lines of text, with some \"quotes\" of various 'types'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Additional leading whitespace is ignored." ]
    Assert [ "$(test::get_env "$app_name" "BLOCK_FOLDED" "$org" "$space")" == "Several lines of text, with some \"quotes\" of various 'types', and also a blank line:
plus another line at the end." ]
    Assert [ "$(test::get_env "$app_name" "BLOCK_LITERAL" "$org" "$space")" == "Several lines of text,
with some \"quotes\" of various 'types',
and also a blank line:

plus another line at the end." ]
    Assert [ "$(test::get_env "$app_name" "HYPHENATED_STRING" "$org" "$space")" == "- strings that start with a hyphen should be quoted" ]
    Assert [ "$(test::get_env "$app_name" "JSON_AS_STRING" "$org" "$space")" == "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }" ]
    Assert [ "$(test::get_env "$app_name" "ARRAY_AS_STRING" "$org" "$space")" == "[ list, of, things ]" ]
  End

  It 'can zero-downtime-push'
    zero_downtime_push() {
      local fixture=$(load_fixture "static-app")
      local config=$(
        %text:expand
        #|$source
        #|params:
        #|  command: zero-downtime-push
        #|  current_app_name: $app_name
        #|  manifest: $fixture/manifest.yml
        #|  path: $fixture/dist
        #|  vars:
        #|    app_name: $app_name
        #|  vars_files: 
        #|    - $fixture/vars-memory.yml
        #|    - $fixture/vars-disk_quota.yml
        #|  environment_variables:
        #|    NEW_ENV_VAR: new env var
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
    Assert [ "$(test::get_env "$app_name" "NEW_ENV_VAR" "$org" "$space")" == "new env var" ]
    Assert [ "$(test::get_env "$app_name" "EXISTING_MANIFEST_ENV_VAR" "$org" "$space")" == "existing value" ]
    Assert [ "$(test::get_env "$app_name" "SINGLE_QUOTED" "$org" "$space")" == "Several lines of text, containing 'single quotes'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(test::get_env "$app_name" "DOUBLE_QUOTED" "$org" "$space")" == "Several lines of text, containing \"double quotes\". Escapes (like \n) work.
In addition, newlines can be escaped to prevent them from being converted to a space.
Newlines can also be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(test::get_env "$app_name" "PLAIN" "$org" "$space")" == "Several lines of text, with some \"quotes\" of various 'types'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Additional leading whitespace is ignored." ]
    Assert [ "$(test::get_env "$app_name" "BLOCK_FOLDED" "$org" "$space")" == "Several lines of text, with some \"quotes\" of various 'types', and also a blank line:
plus another line at the end." ]
    Assert [ "$(test::get_env "$app_name" "BLOCK_LITERAL" "$org" "$space")" == "Several lines of text,
with some \"quotes\" of various 'types',
and also a blank line:

plus another line at the end." ]
    Assert [ "$(test::get_env "$app_name" "HYPHENATED_STRING" "$org" "$space")" == "- strings that start with a hyphen should be quoted" ]
    Assert [ "$(test::get_env "$app_name" "JSON_AS_STRING" "$org" "$space")" == "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }" ]
    Assert [ "$(test::get_env "$app_name" "ARRAY_AS_STRING" "$org" "$space")" == "[ list, of, things ]" ]
  End
End
