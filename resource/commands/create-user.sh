
new_username=$(get_option '.username')
new_password=$(get_option '.password')
new_origin=$(get_option '.origin')

logger::info "Executing $(logger::highlight "$command"): $new_username"

if [ -n "$new_password" ]; then
  cf::create_user_with_password "$new_username" "$new_password"
elif [ -n "$new_origin" ]; then
  cf::create_user_with_origin "$new_username" "$new_origin"
else
  logger::error "Invalid config: Must specify password or origin"
fi
