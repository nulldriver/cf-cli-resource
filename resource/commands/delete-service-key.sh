
service_instance=$(echo $options | jq -r '.service_instance //empty')
service_key=$(echo $options | jq -r '.service_key //empty')

logger::info "Executing $(logger::highlight "$command"): $service_key"

cf::target "$org" "$space"
cf::delete_service_key "$service_instance" "$service_key"
