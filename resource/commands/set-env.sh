
app_name=$(get_option '.app_name')
environment_variables=$(get_option '.environment_variables')

# backwards compatibility for deprecated 'env_var_name' and 'env_var_value' params (https://github.com/nulldriver/cf-cli-resource/issues/71)
env_var_name=$(get_option '.env_var_name')
env_var_value=$(get_option '.env_var_value')
if [ -n "$env_var_name" ]; then
  environment_variables=$(jq -n --arg key "$env_var_name" --arg value "$env_var_value" '{ ($key): $value }')
fi

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

: "${environment_variables:?environment_variables param not set}"

cf::target "$org" "$space"

for key in $(echo $environment_variables | jq -r 'keys[]'); do
  value=$(echo $environment_variables | jq -r --arg key "$key" '.[$key]')
  cf::cf set-env "$app_name" "$key" "$value"
done
