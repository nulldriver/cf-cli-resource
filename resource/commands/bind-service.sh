
app_name=$(get_option '.app_name')
service_instance=$(get_option '.service_instance')
configuration=$(get_option '.configuration')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::bind_service "$app_name" "$service_instance" "$configuration"
