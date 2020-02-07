
app_name=$(get_option '.app_name')
service_instance=$(get_option '.service_instance')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::unbind_service "$app_name" "$service_instance"
