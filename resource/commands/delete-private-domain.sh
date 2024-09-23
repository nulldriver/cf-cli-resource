
domain=$(get_option '.domain')

logger::info "Executing #magenta(%s) on domain #yellow(%s)" "$command" "$domain"

cf::target "$org" "$space"

if cf::is_cf6; then
  cf::cf delete-domain -f "$domain"
else
  cf::cf delete-private-domain -f "$domain"
fi
