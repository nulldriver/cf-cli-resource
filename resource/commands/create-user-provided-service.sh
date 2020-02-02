
service_instance=$(echo $options | jq -r '.service_instance //empty')
credentials=$(echo $options | jq -r '.credentials //empty')
syslog_drain_url=$(echo $options | jq -r '.syslog_drain_url //empty')
route_service_url=$(echo $options | jq -r '.route_service_url //empty')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

if [ -n "$credentials" ]; then
  cf::create_or_update_user_provided_service_credentials "$service_instance" "$credentials"
elif [ -n "$syslog_drain_url" ]; then
  cf::create_or_update_user_provided_service_syslog "$service_instance" "$syslog_drain_url"
elif [ -n "$route_service_url" ]; then
  cf::create_or_update_user_provided_service_route "$service_instance" "$route_service_url"
fi
