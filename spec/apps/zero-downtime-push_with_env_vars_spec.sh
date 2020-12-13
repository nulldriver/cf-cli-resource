#!/usr/bin/env shellspec

set -euo pipefail

Describe 'apps'
  Include resource/lib/cf-functions.sh

  setup() {
    initialize_source_config

    org=$(generate_test_name_with_spaces)
    space=$(generate_test_name_with_spaces)
    app_name=$(generate_test_name_with_hyphens)

    quiet create_org_and_space "$org" "$space"
    quiet login_for_test_assertions "$org" "$space"
  }

  teardown() {
    quiet delete_org_and_space "$org" "$space"
  }

  BeforeAll 'setup'
  AfterAll 'teardown'

  It 'can simple push when current_app_name not used'
    simple_push() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: zero-downtime-push
        #|org: $org
        #|space: $space
        #|manifest: $fixture/manifest.yml
        #|path: $fixture/dist
        #|vars:
        #|  app_name: $app_name
        #|vars_files: 
        #|  - $fixture/vars-memory.yml
        #|  - $fixture/vars-disk_quota.yml
        #|environment_variables:
        #|  NEW_ENV_VAR: new env var
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call simple_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Staging app"
    Assert cf::is_app_started "$app_name"
    Assert [ "$(cf::get_env "$app_name" "NEW_ENV_VAR")" == "new env var" ]
    Assert [ "$(cf::get_env "$app_name" "EXISTING_MANIFEST_ENV_VAR")" == "existing value" ]
    Assert [ "$(cf::get_env "$app_name" "SINGLE_QUOTED")" == "Several lines of text, containing 'single quotes'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "DOUBLE_QUOTED")" == "Several lines of text, containing \"double quotes\". Escapes (like \n) work.
In addition, newlines can be escaped to prevent them from being converted to a space.
Newlines can also be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "PLAIN")" == "Several lines of text, with some \"quotes\" of various 'types'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Additional leading whitespace is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "BLOCK_FOLDED")" == "Several lines of text, with some \"quotes\" of various 'types', and also a blank line:
plus another line at the end." ]
    Assert [ "$(cf::get_env "$app_name" "BLOCK_LITERAL")" == "Several lines of text,
with some \"quotes\" of various 'types',
and also a blank line:

plus another line at the end." ]
    Assert [ "$(cf::get_env "$app_name" "HYPHENATED_STRING")" == "- strings that start with a hyphen should be quoted" ]
    Assert [ "$(cf::get_env "$app_name" "JSON_AS_STRING")" == "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }" ]
    Assert [ "$(cf::get_env "$app_name" "ARRAY_AS_STRING")" == "[ list, of, things ]" ]
  End

  It 'can zero-downtime-push'
    zero_downtime_push() {
      local fixture=$(load_fixture "static-app")
      local params=$(
        %text:expand
        #|command: zero-downtime-push
        #|org: $org
        #|space: $space
        #|current_app_name: $app_name
        #|manifest: $fixture/manifest.yml
        #|path: $fixture/dist
        #|vars:
        #|  app_name: $app_name
        #|vars_files: 
        #|  - $fixture/vars-memory.yml
        #|  - $fixture/vars-disk_quota.yml
        #|environment_variables:
        #|  NEW_ENV_VAR: new env var
      )
      put_with_params "$(yaml_to_json "$params")"
    }
    When call zero_downtime_push
    The status should be success
    The output should json '.version | keys == ["timestamp"]'
    The error should include "Renaming app"
    The error should include "Staging app"
    The error should include "Deleting app"
    Assert cf::is_app_started "$app_name"
    Assert not cf::app_exists "$app_name-venerable"
    Assert [ "$(cf::get_env "$app_name" "NEW_ENV_VAR")" == "new env var" ]
    Assert [ "$(cf::get_env "$app_name" "EXISTING_MANIFEST_ENV_VAR")" == "existing value" ]
    Assert [ "$(cf::get_env "$app_name" "SINGLE_QUOTED")" == "Several lines of text, containing 'single quotes'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "DOUBLE_QUOTED")" == "Several lines of text, containing \"double quotes\". Escapes (like \n) work.
In addition, newlines can be escaped to prevent them from being converted to a space.
Newlines can also be added by leaving a blank line. Leading whitespace on lines is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "PLAIN")" == "Several lines of text, with some \"quotes\" of various 'types'. Escapes (like \n) don't do anything.
Newlines can be added by leaving a blank line. Additional leading whitespace is ignored." ]
    Assert [ "$(cf::get_env "$app_name" "BLOCK_FOLDED")" == "Several lines of text, with some \"quotes\" of various 'types', and also a blank line:
plus another line at the end." ]
    Assert [ "$(cf::get_env "$app_name" "BLOCK_LITERAL")" == "Several lines of text,
with some \"quotes\" of various 'types',
and also a blank line:

plus another line at the end." ]
    Assert [ "$(cf::get_env "$app_name" "HYPHENATED_STRING")" == "- strings that start with a hyphen should be quoted" ]
    Assert [ "$(cf::get_env "$app_name" "JSON_AS_STRING")" == "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }" ]
    Assert [ "$(cf::get_env "$app_name" "ARRAY_AS_STRING")" == "[ list, of, things ]" ]
  End
End
