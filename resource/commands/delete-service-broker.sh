
service_broker=$(get_option '.service_broker')

logger::info "Executing #magenta(%s) on service broker #yellow(%s)" "$command" "$service_broker"

cf::target "$org" "$space"
cf::delete_service_broker "$service_broker"
