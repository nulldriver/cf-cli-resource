
app_name=$(get_option '.app_name')

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"
cf::stop "$app_name"
