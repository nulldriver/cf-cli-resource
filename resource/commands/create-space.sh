
logger::info "Executing #magenta(%s) on space #yellow(%s)" "$command" "$space"

cf::create_space "$org" "$space"
