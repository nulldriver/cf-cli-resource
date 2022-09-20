
domain=$(get_option '.domain')
internal=$(get_option '.internal')

logger::info "Executing $(logger::highlight "$command"): $domain"

args=("$domain")
[ "$internal" == "true" ] && args+=(--internal)

cf::cf create-shared-domain "${args[@]}"
