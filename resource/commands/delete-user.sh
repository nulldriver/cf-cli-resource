
username=$(echo $options | jq -r '.username //empty')

logger::info "Executing $(logger::highlight "$command"): $username"

cf::delete_user "$username"
