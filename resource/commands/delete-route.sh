
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing #magenta(%s) on domain #yellow(%s)" "$command" "$domain"

cf::target "$org" "$space"
cf::delete_route "$domain" "$hostname" "$path"
