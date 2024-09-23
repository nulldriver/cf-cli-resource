
service_instance=$(get_option '.service_instance')
credentials=$(get_option '.credentials')
syslog_drain_url=$(get_option '.syslog_drain_url')
route_service_url=$(get_option '.route_service_url')

logger::info "Executing #magenta(%s) on service instance #yellow(%s)" "$command" "$service_instance"

cf::target "$org" "$space"

if [ -n "$credentials" ]; then
  cf::create_or_update_user_provided_service_credentials "$service_instance" "$credentials"
elif [ -n "$syslog_drain_url" ]; then
  cf::create_or_update_user_provided_service_syslog "$service_instance" "$syslog_drain_url"
elif [ -n "$route_service_url" ]; then
  cf::create_or_update_user_provided_service_route "$service_instance" "$route_service_url"
fi
