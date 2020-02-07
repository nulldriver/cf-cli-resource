
domain=$(get_option '.domain')

logger::info "Executing $(logger::highlight "$command"): $domain"

if cf::has_private_domain "$org" "$domain"; then
  logger::info "$(logger::highlight "Domain $domain already exists")"
else
  cf::create_domain "$org" "$domain"
fi
