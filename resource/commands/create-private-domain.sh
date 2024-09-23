
domain=$(get_option '.domain')

logger::info "Executing #magenta(%s) on domain #yellow(%s)" "$command" "$domain"

if cf::has_private_domain "$org" "$domain"; then
  logger::info "Domain #yellow(%s) already exists" "$domain"
else
  if cf::is_cf6; then
    cf::cf create-domain "$org" "$domain"
  else
    cf::cf create-private-domain "$org" "$domain"
  fi
fi
