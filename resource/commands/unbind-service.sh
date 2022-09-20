
app_name=$(get_option '.app_name')
service_instance=$(get_option '.service_instance')
wait=$(get_option '.wait')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

args=("$app_name" "$service_instance")

if cf::is_cf8 && [ "true" = "$wait" ]; then
  args+=(--wait)
fi

cf::cf unbind-service "${args[@]}"
