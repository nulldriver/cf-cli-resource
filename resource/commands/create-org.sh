
logger::info "Executing $(logger::highlight "$command"): $org"

cf::create_org "$org"
