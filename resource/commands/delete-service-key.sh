
service_instance=$(get_option '.service_instance')
service_key=$(get_option '.service_key')

logger::info "Executing $(logger::highlight "$command"): $service_key"

cf::target "$org" "$space"
cf::delete_service_key "$service_instance" "$service_key"
