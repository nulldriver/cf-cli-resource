
service_instance=$(echo $options | jq -r '.service_instance //empty')
other_space=$(echo $options | jq -r '.other_space //empty')
other_org=$(echo $options | jq -r '.other_org //empty')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::share_service "$service_instance" "$other_space" "$other_org"
