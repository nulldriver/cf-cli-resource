
app_name=$(echo $options | jq -r '.app_name //empty')
task_command=$(echo $options | jq -r '.task_command //empty')
task_name=$(echo $options | jq -r '.task_name //empty')
memory=$(echo $options | jq -r '.memory //empty')
disk_quota=$(echo $options | jq -r '.disk_quota //empty')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::run_task "$app_name" "$task_command" "$task_name" "$memory" "$disk_quota"
