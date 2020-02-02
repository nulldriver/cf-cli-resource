
service_broker=$(echo $options | jq -r '.service_broker //empty')
service=$(echo $options | jq -r '.service //empty')
plan=$(echo $options | jq -r '.plan //empty')
access_org=$(echo $options | jq -r '.access_org //empty')

logger::info "Executing $(logger::highlight "$command"): $service"

# backwards compatibility for deprecated 'service_broker' param (https://github.com/nulldriver/cf-cli-resource/issues/21)
service=${service:-$service_broker}

cf::enable_service_access "$service" "$plan" "$access_org"
