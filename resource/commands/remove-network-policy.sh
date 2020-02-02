
source_app=$(echo $options | jq -r '.source_app //empty')
destination_app=$(echo $options | jq -r '.destination_app //empty')
protocol=$(echo $options | jq -r '.protocol //empty')
port=$(echo $options | jq -r '.port //empty')

logger::info "Executing $(logger::highlight "$command"): $source_app"

cf::target "$org" "$space"
cf::remove_network_policy "$source_app" "$destination_app" "$protocol" "$port"
