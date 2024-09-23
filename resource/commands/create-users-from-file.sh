
file=$(get_option '.file')

logger::info "Executing #magenta(%s) on file #yellow(%s)" "$command" "$file"

cf::create_users_from_file "$file"
