
service_instance=$(get_option '.service_instance')
plan=$(get_option '.plan')
configuration=$(get_option '.configuration')
tags=$(get_option '.tags')
timeout=$(get_option '.timeout')
wait=$(get_option '.wait_for_service' 'false')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::update_service "$service_instance" "$plan" "$configuration" "$tags"

if [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
