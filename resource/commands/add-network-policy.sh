
source_app=$(get_option '.source_app')
destination_app=$(get_option '.destination_app')
protocol=$(get_option '.protocol')
port=$(get_option '.port')

logger::info "Executing $(logger::highlight "$command"): $source_app"

cf::target "$org" "$space"
cf::add_network_policy "$source_app" "$destination_app" "$protocol" "$port"
