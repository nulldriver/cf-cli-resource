
app_name=$(echo $options | jq -r '.app_name //empty')
instances=$(echo $options | jq -r '.instances //empty')
memory=$(echo $options | jq -r '.memory //empty')
disk_quota=$(echo $options | jq -r '.disk_quota //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::scale "$app_name" "$instances" "$memory" "$disk_quota"
