
logger::info "Executing #magenta(%s) on org #yellow(%s)" "$command" "$org"

cf::create_org "$org"
