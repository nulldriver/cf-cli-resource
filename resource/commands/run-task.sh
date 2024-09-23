
app_name=$(get_option '.app_name')
task_command=$(get_option '.task_command')
task_name=$(get_option '.task_name')
memory=$(get_option '.memory')
disk_quota=$(get_option '.disk_quota')

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"

args=("$app_name")

if cf::is_cf6; then
  args+=("$task_command")
elif [ -n "$task_command" ]; then
  args+=(--command "$task_command")
fi

[ -n "$task_name" ] && args+=(--name "$task_name")
[ -n "$memory" ] && args+=(-m "$memory")
[ -n "$disk_quota" ] && args+=(-k "$disk_quota")

cf::cf run-task "${args[@]}"
