
domain=$(get_option '.domain')
service_instance=$(get_option '.service_instance')
hostname=$(get_option '.hostname')
path=$(get_option '.path')
configuration=$(get_option '.configuration')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

args=("$domain" "$service_instance")
[ -n "$hostname" ] && args+=(--hostname "$hostname")
[ -n "$path" ] && args+=(--path "$path")
[ -n "$configuration" ] && args+=(-c "$configuration")

cf::cf bind-route-service "${args[@]}"
