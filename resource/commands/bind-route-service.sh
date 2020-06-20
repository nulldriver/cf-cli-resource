
domain=$(get_option '.domain')
service_instance=$(get_option '.service_instance')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

args=("$domain" "$service_instance")
[ -n "$hostname" ] && args+=(--hostname "$hostname")
[ -n "$path" ] && args+=(--path "$path")

cf::cf bind-route-service "${args[@]}"
