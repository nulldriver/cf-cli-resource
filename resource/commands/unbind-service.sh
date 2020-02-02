
app_name=$(echo $options | jq -r '.app_name //empty')
service_instance=$(echo $options | jq -r '.service_instance //empty')

logger::info "Executing $(logger::highlight "$command"): $service_instance"

cf::target "$org" "$space"
cf::unbind_service "$app_name" "$service_instance"
