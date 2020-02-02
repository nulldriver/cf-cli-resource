
buildpack=$(echo $options | jq -r '.buildpack //empty')
stack=$(echo $options | jq -r '.stack //empty')

logger::info "Executing $(logger::highlight "$command"): $buildpack"

args=("$buildpack")
[ -n "$stack" ] && args+=(-s "$stack")

cf delete-buildpack -f "${args[@]}"
