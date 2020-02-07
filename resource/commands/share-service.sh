
service_instance=$(get_option '.service_instance')
other_space=$(get_option '.other_space')
other_org=$(get_option '.other_org')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::share_service "$service_instance" "$other_space" "$other_org"
