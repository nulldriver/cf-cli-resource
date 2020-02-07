
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::delete_route "$domain" "$hostname" "$path"
