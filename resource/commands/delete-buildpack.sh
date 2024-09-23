
buildpack=$(get_option '.buildpack')
stack=$(get_option '.stack')

logger::info "Executing #magenta(%s) on buildpack #yellow(%s)" "$command" "$buildpack"

args=("$buildpack")
[ -n "$stack" ] && args+=(-s "$stack")

cf::cf delete-buildpack -f "${args[@]}"
