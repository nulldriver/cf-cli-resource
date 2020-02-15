
service=$(get_option '.service')
plan=$(get_option '.plan')
service_instance=$(get_option '.service_instance')
broker=$(get_option '.broker')
configuration=$(get_option '.configuration')
tags=$(get_option '.tags')
timeout=$(get_option '.timeout')
wait=$(get_option '.wait_for_service' 'false')
update_service=$(get_option '.update_service' 'false')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

if [ "true" = "$update_service" ]; then
  cf::create_or_update_service "$service" "$plan" "$service_instance" "$broker" "$configuration" "$tags"
else
  cf::create_service "$service" "$plan" "$service_instance" "$broker" "$configuration" "$tags"
fi

if [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
