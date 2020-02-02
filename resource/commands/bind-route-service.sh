
domain=$(echo $options | jq -r '.domain //empty')
service_instance=$(echo $options | jq -r '.service_instance //empty')
hostname=$(echo $options | jq -r '.hostname //empty')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::bind_route_service "$domain" "$service_instance" "$hostname"
