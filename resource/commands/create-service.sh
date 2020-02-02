
service=$(echo $options | jq -r '.service //empty')
plan=$(echo $options | jq -r '.plan //empty')
service_instance=$(echo $options | jq -r '.service_instance //empty')
configuration=$(echo $options | jq -r '.configuration //empty')
tags=$(echo $options | jq -r '.tags //empty')
timeout=$(echo $options | jq -r '.timeout //empty')
wait=$(echo $options | jq -r '.wait_for_service //"false"')
update_service=$(echo $options | jq -r '.update_service //"false"')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"

if [ "true" = "$update_service" ]; then
  cf::create_or_update_service "$service" "$plan" "$service_instance" "$configuration" "$tags"
else
  cf::create_service "$service" "$plan" "$service_instance" "$configuration" "$tags"
fi

if [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
