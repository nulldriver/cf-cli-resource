
username=$(get_option '.username')
origin=$(get_option '.origin')

logger::info "Executing #magenta(%s) on user #yellow(%s)" "$command" "$username"

cf::delete_user "$username" "$origin"
