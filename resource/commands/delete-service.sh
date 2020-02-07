
service_instance=$(get_option '.service_instance')
timeout=$(get_option '.timeout')
wait=$(get_option '.wait_for_service' 'false')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::delete_service "$service_instance"

if [ "true" = "$wait" ]; then
  cf::wait_for_delete_service_instance "$service_instance" "$timeout"
fi
