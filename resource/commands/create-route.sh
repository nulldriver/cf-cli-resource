
other_space=$(echo $options | jq -r '.other_space //empty')
domain=$(echo $options | jq -r '.domain //empty')
hostname=$(echo $options | jq -r '.hostname //empty')
path=$(echo $options | jq -r '.path //empty')

logger::info "Executing $(logger::highlight "$command"): $domain"

cf::target "$org" "$space"
cf::create_route "${other_space:-$space}" "$domain" "$hostname" "$path"
