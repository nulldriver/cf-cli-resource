
service_broker=$(echo $options | jq -r '.service_broker //empty')
username=$(echo $options | jq -r '.username //empty')
password=$(echo $options | jq -r '.password //empty')
url=$(echo $options | jq -r '.url //empty')
is_space_scoped=$(echo $options | jq -r '.space_scoped //"false"')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

if [ "true" = "$is_space_scoped" ]; then
  cf::target "$org" "$space"
fi

cf::create_service_broker "$service_broker" "$username" "$password" "$url" "$is_space_scoped"
