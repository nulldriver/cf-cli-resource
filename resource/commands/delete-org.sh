
logger::info "Executing #magenta(%s) on org #yellow(%s)" "$command" "$org"

cf::delete_org "$org"
