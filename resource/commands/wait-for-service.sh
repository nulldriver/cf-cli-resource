
service_instance=$(get_option '.service_instance')
timeout=$(get_option '.timeout')

logger::info "Executing #magenta(%s) on service instance #yellow(%s)" "$command" "$service_instance"

cf::target "$org" "$space"
cf::wait_for_service_instance "$service_instance" "$timeout"
