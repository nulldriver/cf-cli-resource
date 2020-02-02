
buildpack=$(echo $options | jq -r '.buildpack //empty')
enabled=$(echo $options | jq -r '.enabled //empty')
locked=$(echo $options | jq -r '.locked //empty')
assign_stack=$(echo $options | jq -r '.assign_stack //empty')
path=$(echo $options | jq -r '.path //empty')
position=$(echo $options | jq -r '.position //empty')

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
