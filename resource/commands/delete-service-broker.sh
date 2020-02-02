
service_broker=$(echo $options | jq -r '.service_broker //empty')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

cf::target "$org" "$space"
cf::delete_service_broker "$service_broker"
