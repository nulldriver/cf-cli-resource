
service_instance=$(get_option '.service_instance')
timeout=$(get_option '.timeout')
wait_for_service=$(get_option '.wait_for_service')
wait=$(get_option '.wait')

# backwards compatibility for deprecated 'wait_for_service' param
wait=${wait:-$wait_for_service}

logger::info "Executing #magenta(%s) on service instance #yellow(%s)" "$command" "$service_instance"

cf::target "$org" "$space"

args=(-f "$service_instance")

if cf::is_cf8 && [ "true" = "$wait" ]; then
  args+=(--wait)
fi

cf::cf delete-service "${args[@]}"

if ! cf::is_cf8 && [ "true" = "$wait" ]; then
  cf::wait_for_delete_service_instance "$service_instance" "$timeout"
fi
