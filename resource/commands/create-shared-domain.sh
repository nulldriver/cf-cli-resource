
domain=$(get_option '.domain')
internal=$(get_option '.internal')

logger::info "Executing #magenta(%s) on domain #yellow(%s)" "$command" "$domain"

args=("$domain")
[ "$internal" == "true" ] && args+=(--internal)

cf::cf create-shared-domain "${args[@]}"
