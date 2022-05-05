
service_instance=$(get_option '.service_instance')
service_key=$(get_option '.service_key')
wait=$(get_option '.wait')

logger::info "Executing $(logger::highlight "$command"): $service_key"

cf::target "$org" "$space"

args=(-f "$service_instance" "$service_key")

if cf::is_cf8 && [ "true" = "$wait" ]; then
  args+=(--wait)
fi

cf::cf delete-service-key "${args[@]}"
