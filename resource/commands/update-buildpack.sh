
buildpack=$(get_option '.buildpack')
enabled=$(get_option '.enabled')
locked=$(get_option '.locked')
assign_stack=$(get_option '.assign_stack')
path=$(get_option '.path')
position=$(get_option '.position')

logger::info "Executing $(logger::highlight "$command"): $buildpack"

args=("$buildpack")
[ "$enabled" == "true"  ] && args+=(--enable)
[ "$enabled" == "false" ] && args+=(--disable)
[ "$locked"  == "true"  ] && args+=(--lock)
[ "$locked"  == "false" ] && args+=(--unlock)

[ -n "$assign_stack" ] && args+=(--assign-stack "$assign_stack")
[ -n "$path" ] && args+=(-p $path) # don't quote so we can support globbing
[ -n "$position" ] && args+=(-i "$position")

cf update-buildpack "${args[@]}"
