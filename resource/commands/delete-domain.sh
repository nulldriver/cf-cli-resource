
domain=$(echo $options | jq -r '.domain //empty')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::delete_domain "$domain"
