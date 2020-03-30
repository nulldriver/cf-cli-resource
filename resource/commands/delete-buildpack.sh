
buildpack=$(get_option '.buildpack')
stack=$(get_option '.stack')

logger::info "Executing $(logger::highlight "$command"): $buildpack"

args=("$buildpack")
[ -n "$stack" ] && args+=(-s "$stack")

cf::cf delete-buildpack -f "${args[@]}"
