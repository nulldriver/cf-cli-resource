
service_broker=$(get_option '.service_broker')
service=$(get_option '.service')
broker=$(get_option '.broker')
plan=$(get_option '.plan')
access_org=$(get_option '.access_org')

logger::info "Executing $(logger::highlight "$command"): $service_broker"

# backwards compatibility for deprecated 'service_broker' param (https://github.com/nulldriver/cf-cli-resource/issues/21)
service=${service:-$service_broker}

args=("$service")
[ -n "$broker" ] && args+=(-b "$broker")
[ -n "$plan" ] && args+=(-p "$plan")
[ -n "$access_org" ] && args+=(-o "$access_org")

cf::cf disable-service-access "${args[@]}"
