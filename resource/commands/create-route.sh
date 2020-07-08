
other_space=$(get_option '.other_space')
domain=$(get_option '.domain')
hostname=$(get_option '.hostname')
path=$(get_option '.path')

logger::info "Executing $(logger::highlight "$command"): $domain"

args=()
if cf::is_cf7; then
  cf::target "$org" "${other_space:-$space}"
  args+=("$domain")
else
  cf::target "$org" "$space"
  args+=("${other_space:-$space}" "$domain")
fi

[ -n "$hostname" ] && args+=(--hostname "$hostname")
[ -n "$path" ]     && args+=(--path "$path")

cf::cf create-route "${args[@]}"
