
service_instance=$(get_option '.service_instance')
plan=$(get_option '.plan')
configuration=$(get_option '.configuration')
tags=$(get_option '.tags')
timeout=$(get_option '.timeout')
wait_for_service=$(get_option '.wait_for_service')
wait=$(get_option '.wait')

# backwards compatibility for deprecated 'wait_for_service' param
wait=${wait:-$wait_for_service}

logger::info "Executing #magenta(%s) on service instance #yellow(%s)" "$command" "$service_instance"

cf::target "$org" "$space"
cf::update_service "$service_instance" "$plan" "$configuration" "$tags" "$wait"

if ! cf::is_cf8 && [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
