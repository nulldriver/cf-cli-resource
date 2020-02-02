
app_name=$(echo $options | jq -r '.app_name //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::stop "$app_name"
