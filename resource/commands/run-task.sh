
app_name=$(get_option '.app_name')
task_command=$(get_option '.task_command')
task_name=$(get_option '.task_name')
memory=$(get_option '.memory')
disk_quota=$(get_option '.disk_quota')

logger::info "Executing $(logger::highlight "$command"): $app_name"

cf::target "$org" "$space"
cf::run_task "$app_name" "$task_command" "$task_name" "$memory" "$disk_quota"
