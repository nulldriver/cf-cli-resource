
app_name=$(get_option '.app_name')
strategy=$(get_option '.strategy')
no_wait=$(get_option '.no_wait')
staging_timeout=$(get_option '.staging_timeout' 0)
startup_timeout=$(get_option '.startup_timeout' 0)

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"

[ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
[ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

args=("$app_name")

if ! cf::is_cf6; then
  [ -n "$strategy" ] && args+=(--strategy "$strategy")
  [ "$no_wait" == "true"  ] && args+=(--no-wait)
fi

cf::cf restage "${args[@]}"

unset CF_STAGING_TIMEOUT
unset CF_STARTUP_TIMEOUT
