#!/usr/bin/env shellspec

set -euo pipefail

Describe 'util'
  Include resource/lib/util.sh

  setup() {
    fixture=$(load_fixture "static-app")

    json=$(jq -n '{
      source: {
        api: "api.example.com",
        username: "admin",
        password: "pa55word"
      },
      params: {
        command: "push",
        app_name: "myapp"
      }
    }')

    yaml=$(
      %text:expand
      #|source:
      #|  api: api.example.com
      #|  username: admin
      #|  password: pa55word
      #|params:
      #|  command: push
      #|  app_name: myapp
    )
  }

  BeforeAll 'setup'

  It 'can convert json to yaml'
    When call util::json_to_yaml "$json"
    The status should be success
    The output should eq "$yaml"
  End

  It 'can convert yaml string to json'
    When call util::yaml_to_json "$yaml"
    The status should be success
    The output should json "$json"
  End

  It 'can convert yaml file to json'
    echo "$yaml" > "$fixture/file.yaml"

    When call util::yaml_to_json "$yaml"
    The status should be success
    The output should json "$json"
  End

  It 'can tell if it is json'
    When call util::is_json "{}"
    The status should be success
  End

  It 'can tell if it is NOT json'
    When call util::is_json "not json"
    The status should be failure
  End

  It 'can push a value onto a json array'
    When call util::json_array_push '["staticfile_buildpack"]' "java_buildpack_offline"
    The status should be success
    The output should json '[ "staticfile_buildpack", "java_buildpack_offline" ]'
  End

  It 'can set manifest environment variables with app name'
    local environment_variables=$(
      %text
      #|{
      #|  "KEY1": "value 1",
      #|  "KEY2": "another value"
      #|}
    )

    local manifest_before=$(
      %text
      #|applications:
      #|  - name: myapp
      #|    path: path/to/myapp
    )
    echo "$manifest_before" > "$fixture/manifest_with_app_name.yml"

    local manifest_after=$(
      %text
      #|applications:
      #|  - name: myapp
      #|    path: path/to/myapp
      #|    env:
      #|      KEY1: value 1
      #|      KEY2: another value
    )

    When call util::set_manifest_environment_variables "$fixture/manifest_with_app_name.yml" "$environment_variables" "myapp"
    The status should be success
    local contents=$(cat "$fixture/manifest_with_app_name.yml")
    The variable contents should eq "$manifest_after"
  End

  It 'can set manifest environment variables with single un-named application'
    local environment_variables=$(
      %text
      #|{
      #|  "KEY1": "value 1",
      #|  "KEY2": "another value"
      #|}
    )

    local manifest_before=$(
      %text
      #|applications:
      #|  - path: path/to/myapp
    )
    echo "$manifest_before" > "$fixture/manifest_with_single_un-named_app.yml"

    local manifest_after=$(
      %text
      #|applications:
      #|  - path: path/to/myapp
      #|    env:
      #|      KEY1: value 1
      #|      KEY2: another value
    )

    When call util::set_manifest_environment_variables "$fixture/manifest_with_single_un-named_app.yml" "$environment_variables" "myapp"
    The status should be success
    local contents=$(cat "$fixture/manifest_with_single_un-named_app.yml")
    The variable contents should eq "$manifest_after"
  End

  It 'can set manifest environment variables globally'
    local environment_variables=$(
      %text
      #|{
      #|  "KEY1": "value 1",
      #|  "KEY2": "another value"
      #|}
    )

    local manifest_before=$(
      %text
      #|services:
      #|  - clockwork-mysql
    )
    echo "$manifest_before" > "$fixture/manifest_globally.yml"

    local manifest_after=$(
      %text
      #|services:
      #|  - clockwork-mysql
      #|env:
      #|  KEY1: value 1
      #|  KEY2: another value
    )

    When call util::set_manifest_environment_variables "$fixture/manifest_globally.yml" "$environment_variables" "myapp"
    The status should be success
    local contents=$(cat "$fixture/manifest_globally.yml")
    The variable contents should eq "$manifest_after"
  End
End
