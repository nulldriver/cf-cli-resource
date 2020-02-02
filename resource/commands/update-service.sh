
service_instance=$(echo $options | jq -r '.service_instance //empty')
plan=$(echo $options | jq -r '.plan //empty')
configuration=$(echo $options | jq -r '.configuration //empty')
tags=$(echo $options | jq -r '.tags //empty')
timeout=$(echo $options | jq -r '.timeout //empty')
wait=$(echo $options | jq -r '.wait_for_service //"false"')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::update_service "$service_instance" "$plan" "$configuration" "$tags"

if [ "true" = "$wait" ]; then
  cf::wait_for_service_instance "$service_instance" "$timeout"
fi
