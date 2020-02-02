
app_name=$(echo $options | jq -r '.app_name //empty')
domain=$(echo $options | jq -r '.domain //empty')
hostname=$(echo $options | jq -r '.hostname //empty')
path=$(echo $options | jq -r '.path //empty')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::map_route "$app_name" "$domain" "$hostname" "$path"
