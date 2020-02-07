
app_name=$(get_option '.app_name')
env_var_name=$(get_option '.env_var_name')
env_var_value=$(get_option '.env_var_value')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::set_env "$app_name" "$env_var_name" "$env_var_value"
