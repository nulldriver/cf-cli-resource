
app_name=$(echo $options | jq -r '.app_name //empty')
delete_mapped_routes=$(echo $options | jq -r '.delete_mapped_routes //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::delete "$app_name" "$delete_mapped_routes"
