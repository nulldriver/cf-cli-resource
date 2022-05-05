
app_name=$(get_option '.app_name')
service_instance=$(get_option '.service_instance')
configuration=$(get_option '.configuration')
binding_name=$(get_option '.binding_name')
wait=$(get_option '.wait')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

args=("$app_name" "$service_instance")
[ -n "$configuration" ] && args+=(-c "$configuration")
[ -n "$binding_name" ] && args+=(--binding-name "$binding_name")

if cf::is_cf8 && [ "true" = "$wait" ]; then
  args+=(--wait)
fi

cf::cf bind-service "${args[@]}"
