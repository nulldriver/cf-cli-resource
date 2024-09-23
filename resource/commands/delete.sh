
app_name=$(get_option '.app_name')
delete_mapped_routes=$(get_option '.delete_mapped_routes')

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"
cf::delete "$app_name" "$delete_mapped_routes"
