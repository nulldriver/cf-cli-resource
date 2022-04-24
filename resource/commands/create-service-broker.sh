
service_broker=$(get_option '.service_broker')
username=$(get_option '.username')
password=$(get_option '.password')
url=$(get_option '.url')
is_space_scoped=$(get_option '.space_scoped' 'false')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

if [ "true" = "$is_space_scoped" ]; then
  cf::target "$org" "$space"
fi

cf::create_or_update_service_broker "$service_broker" "$username" "$password" "$url" "$is_space_scoped"
