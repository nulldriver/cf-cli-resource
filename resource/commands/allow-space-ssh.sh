
logger::info "Executing #magenta(%s) on space #yellow(%s)" "$command" "$space"

cf::target "$org" "$space"
cf::cf allow-space-ssh "$space"
