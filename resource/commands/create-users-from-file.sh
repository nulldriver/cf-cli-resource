
file=$(echo $options | jq -r '.file //empty')

logger::info "Executing $(logger::highlight "$command"): $file"

cf::create_users_from_file "$file"
