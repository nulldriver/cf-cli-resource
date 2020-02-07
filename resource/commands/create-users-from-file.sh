
file=$(get_option '.file')

logger::info "Executing $(logger::highlight "$command"): $file"

cf::create_users_from_file "$file"
