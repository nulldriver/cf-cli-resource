
service_instance=$(echo $options | jq -r '.service_instance //empty')
timeout=$(echo $options | jq -r '.timeout //empty')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::wait_for_service_instance "$service_instance" "$timeout"
