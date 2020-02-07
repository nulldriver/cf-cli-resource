
app_name=$(get_option '.app_name')
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::unmap_route "$app_name" "$domain" "$hostname" "$path"
