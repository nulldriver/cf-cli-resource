
service_broker=$(get_option '.service_broker')
service=$(get_option '.service')
plan=$(get_option '.plan')
access_org=$(get_option '.access_org')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

# backwards compatibility for deprecated 'service_broker' param (https://github.com/nulldriver/cf-cli-resource/issues/21)
service=${service:-$service_broker}

cf::disable_service_access "$service" "$plan" "$access_org"
