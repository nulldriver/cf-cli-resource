
service_instance=$(echo $options | jq -r '.service_instance //empty')
timeout=$(echo $options | jq -r '.timeout //empty')
wait=$(echo $options | jq -r '.wait_for_service //"false"')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::delete_service "$service_instance"

if [ "true" = "$wait" ]; then
  cf::wait_for_delete_service_instance "$service_instance" "$timeout"
fi
