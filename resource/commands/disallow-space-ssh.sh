
logger::info "Executing #magenta(%s) on space #yellow(%s)" "$command" "$space"

cf::target "$org" "$space"
cf::cf disallow-space-ssh "$space"
