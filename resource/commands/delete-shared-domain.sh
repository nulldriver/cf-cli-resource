
domain=$(get_option '.domain')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org"

cf::cf delete-shared-domain -f "$domain"
