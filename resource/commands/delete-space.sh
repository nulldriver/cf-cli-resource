
logger::info "Executing $(logger::highlight "$command"): $space"

cf::delete_space "$org" "$space"
