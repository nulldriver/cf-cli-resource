
domain=$(get_option '.domain')
service_instance=$(get_option '.service_instance')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::bind_route_service "$domain" "$service_instance" "$hostname" "$path"
