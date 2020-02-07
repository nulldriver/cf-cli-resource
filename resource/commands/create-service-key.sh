
service_instance=$(get_option '.service_instance')
service_key=$(get_option '.service_key')
configuration=$(get_option '.configuration')

logger::info "Executing $(logger::highlight "$command"): $service_key"

cf::target "$org" "$space"
cf::create_service_key "$service_instance" "$service_key" "$configuration"
