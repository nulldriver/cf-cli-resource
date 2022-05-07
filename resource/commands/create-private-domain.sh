
domain=$(get_option '.domain')

logger::info "Executing $(logger::highlight "$command"): $domain"

if cf::has_private_domain "$org" "$domain"; then
  logger::info "$(logger::highlight "Domain $domain already exists")"
else
  if cf::is_cf6; then
    cf::cf create-domain "$org" "$domain"
  else
    cf::cf create-private-domain "$org" "$domain"
  fi
fi
