
service=$(get_option '.service')
plan=$(get_option '.plan')
service_instance=$(get_option '.service_instance')
broker=$(get_option '.broker')
configuration=$(get_option '.configuration')
tags=$(get_option '.tags')
timeout=$(get_option '.timeout')
wait_for_service=$(get_option '.wait_for_service')
wait=$(get_option '.wait')
update_service=$(get_option '.update_service')

# backwards compatibility for deprecated 'wait_for_service' param
wait=${wait:-$wait_for_service}

logger::info "Executing #magenta(%s) on service instance #yellow(%s)" "$command" "$service_instance"

cf::target "$org" "$space"

if [ "true" = "$update_service" ] && cf::service_exists "$service_instance"; then
  cf::update_service "$service_instance" "$plan" "$configuration" "$tags" "$wait"
else
  args=("$service" "$plan" "$service_instance")
  [ -n "$broker" ]        && args+=(-b "$broker")
  [ -n "$configuration" ] && args+=(-c "$configuration")
  [ -n "$tags" ]          && args+=(-t "$tags")

  if cf::is_cf8 && [ "true" = "$wait" ]; then
    args+=(--wait)
  fi

  cf::cf create-service "${args[@]}"
fi

if ! cf::is_cf8 && [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
