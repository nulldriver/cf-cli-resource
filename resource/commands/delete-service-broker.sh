
service_broker=$(get_option '.service_broker')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

cf::target "$org" "$space"
cf::delete_service_broker "$service_broker"
