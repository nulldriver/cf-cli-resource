
username=$(get_option '.username')

logger::info "Executing $(logger::highlight "$command"): $username"

cf::delete_user "$username"
