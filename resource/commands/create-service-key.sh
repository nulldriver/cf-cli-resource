
service_instance=$(get_option '.service_instance')
service_key=$(get_option '.service_key')
configuration=$(get_option '.configuration')
wait=$(get_option '.wait')

logger::info "Executing #magenta(%s) on service key #yellow(%s)" "$command" "$service_key"

cf::target "$org" "$space"

args=("$service_instance" "$service_key")
[ -n "$configuration" ] && args+=(-c "$configuration")

if cf::is_cf8 && [ "true" = "$wait" ]; then
  args+=(--wait)
fi

cf::cf create-service-key "${args[@]}"
