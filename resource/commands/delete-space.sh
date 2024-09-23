
logger::info "Executing #magenta(%s) on space #yellow(%s)" "$command" "$space"

cf::delete_space "$org" "$space"
