
domain=$(echo $options | jq -r '.domain //empty')
hostname=$(echo $options | jq -r '.hostname //empty')
path=$(echo $options | jq -r '.path //empty')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::delete_route "$domain" "$hostname" "$path"
