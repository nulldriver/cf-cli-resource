
logger::info "Executing $(logger::highlight "$command"): $space"

cf::create_space "$org" "$space"
