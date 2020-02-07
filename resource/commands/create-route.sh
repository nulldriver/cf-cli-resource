
other_space=$(get_option '.other_space')
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::create_route "${other_space:-$space}" "$domain" "$hostname" "$path"
