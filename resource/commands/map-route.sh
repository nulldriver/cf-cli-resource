
app_name=$(get_option '.app_name')
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')
app_protocol=$(get_option '.app_protocol')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"

args=("$app_name" "$domain")
[ -n "$hostname" ] && args+=(--hostname "$hostname")
[ -n "$path" ]     && args+=(--path "$path")

if cf::is_cf8; then
  [ -n "$app_protocol" ] && args+=(--app-protocol "$app_protocol")
fi

cf::cf map-route "${args[@]}"
