
username=$(get_option '.username')
origin=$(get_option '.origin')

logger::info "Executing $(logger::highlight "$command"): $username"

cf::delete_user "$username" "$origin"
