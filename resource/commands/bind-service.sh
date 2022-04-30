
app_name=$(get_option '.app_name')
service_instance=$(get_option '.service_instance')
configuration=$(get_option '.configuration')
binding_name=$(get_option '.binding_name')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::bind_service "$app_name" "$service_instance" "$configuration" "$binding_name"
