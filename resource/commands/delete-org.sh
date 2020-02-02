
logger::info "Executing $(logger::highlight "$command"): $org"

cf::delete_org "$org"
