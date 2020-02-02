
buildpack=$(echo $options | jq -r '.buildpack //empty')
path=$(echo $options | jq -r '.path //empty')
position=$(echo $options | jq -r '.position //empty')
enabled=$(echo $options | jq -r '.enabled //empty')

logger::info "Executing $(logger::highlight "$command"): $buildpack"

args=("$buildpack" $path "$position") # don't quote $path so we can support globbing
[ "$enabled" == "true" ]  && args+=(--enable)
[ "$enabled" == "false" ] && args+=(--disable)

cf create-buildpack "${args[@]}"
