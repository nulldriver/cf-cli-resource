
app_name=$(echo $options | jq -r '.app_name //empty')
env_var_name=$(echo $options | jq -r '.env_var_name //empty')
env_var_value=$(echo $options | jq -r '.env_var_value //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::set_env "$app_name" "$env_var_name" "$env_var_value"
