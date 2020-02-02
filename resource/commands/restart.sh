
app_name=$(echo $options | jq -r '.app_name //empty')
staging_timeout=$(echo $options | jq -r '.staging_timeout //empty')
startup_timeout=$(echo $options | jq -r '.startup_timeout //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::restart "$app_name" "$staging_timeout" "$startup_timeout"
