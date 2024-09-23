
app_name=$(get_option '.app_name')
instances=$(get_option '.instances')
memory=$(get_option '.memory')
disk_quota=$(get_option '.disk_quota')

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"
cf::scale "$app_name" "$instances" "$memory" "$disk_quota"
