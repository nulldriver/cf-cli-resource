
space=$(get_option '.space')

logger::info "Executing $(logger::highlight "$command"): $space"

cf::target "$org" "$space"
cf::cf allow-space-ssh "$space"