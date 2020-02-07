
domain=$(get_option '.domain')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::delete_domain "$domain"
