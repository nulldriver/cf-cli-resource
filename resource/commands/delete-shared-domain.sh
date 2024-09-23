
domain=$(get_option '.domain')

logger::info "Executing #magenta(%s) on domain #yellow(%s)" "$command" "$domain"

cf::target "$org"

cf::cf delete-shared-domain -f "$domain"
