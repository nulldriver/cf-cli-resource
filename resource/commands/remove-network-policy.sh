
source_app=$(get_option '.source_app')
destination_app=$(get_option '.destination_app')
destination_org=$(get_option '.destination_org')
destination_space=$(get_option '.destination_space')
protocol=$(get_option '.protocol')
port=$(get_option '.port')

logger::info "Executing $(logger::highlight "$command"): $source_app"

cf::target "$org" "$space"

args=("$source_app")

if cf::is_cf7; then
  args+=("$destination_app")
else
  args+=(--destination-app "$destination_app")
fi

args+=(--protocol "$protocol" --port "$port")
[ -n "$destination_org" ] && args+=(-o "$destination_org")
[ -n "$destination_space" ] && args+=(-s "$destination_space")

cf::cf remove-network-policy "${args[@]}"
