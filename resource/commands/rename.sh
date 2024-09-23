
app_name=$(get_option '.app_name')
new_app_name=$(get_option '.new_app_name')

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"
cf::rename "$app_name" "$new_app_name"
