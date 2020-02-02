
app_name=$(echo $options | jq -r '.app_name //empty')
new_app_name=$(echo $options | jq -r '.new_app_name //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::rename "$app_name" "$new_app_name"
