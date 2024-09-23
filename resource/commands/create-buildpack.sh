
buildpack=$(get_option '.buildpack')
path=$(get_option '.path')
position=$(get_option '.position')
enabled=$(get_option '.enabled')

logger::info "Executing #magenta(%s) on buildpack #yellow(%s)" "$command" "$buildpack"

args=("$buildpack" $path "$position") # don't quote $path so we can support globbing
[ "$enabled" == "false" ] && args+=(--disable)

cf::cf create-buildpack "${args[@]}"
