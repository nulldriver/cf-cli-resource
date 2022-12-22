
util::is_json() {
  local json=${1:?json null or not set}
  echo "$json" | jq . 1>/dev/null 2>&1
}

util::json_to_yaml() {
  local json=${1:?json null or not set}
  echo "$json" | yq - --prettyPrint
}

util::yaml_to_json() {
  local yaml=${1:?yaml null or not set}

  if [ -r "$yaml" ]; then
    yq --output-format json "$yaml"
  else
    echo "$yaml" | yq - --output-format json
  fi
}

util::json_array_push() {
  local array=${1:?array null or not set}
  local value=${2:-}
  if [ -n "$value" ]; then
    echo "$array" | jq --arg value "$value" '. + [ $value ]'
  else
    echo "$array"
  fi
}

util::set_manifest_environment_variables() (
  local manifest=${1:?manifest null or not set}
  local environment_variables=${2:?environment_variables null or not set}
  local app_name=${3:-}

  get_keys() {
    echo "$environment_variables" | jq -r 'keys[]'
  }

  get_value() {
    local key=${1:?key null or not set}
    echo "$environment_variables" | jq -r --arg key "$key" '.[$key]'
  }

  has_named_app() {
    [ -n "$app_name" ] && name=$app_name yq -e '.applications[].name == env(name)' "$manifest" >/dev/null 2>&1
  }

  has_one_unnamed_app() {
    [ "1" == "$(yq '.applications | length' "$manifest")" ]
  }

  for key in $(get_keys); do
    local value=$(get_value "$key")
    if has_named_app; then
      name=$app_name key=$key value=$value yq --inplace '(.applications[] | select(.name == env(name)) | .env[env(key)]) = strenv(value)' "$manifest"
    elif has_one_unnamed_app; then
      name=$app_name key=$key value=$value yq --inplace '(.applications[0].env[env(key)]) = strenv(value)' "$manifest"
    else
      key=$key value=$value yq --inplace '.env[env(key)] = strenv(value)' "$manifest"
    fi
  done
)
