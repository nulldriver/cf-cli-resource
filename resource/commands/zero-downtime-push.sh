
manifest=$(get_option '.manifest')
path=$(get_option '.path')
current_app_name=$(get_option '.current_app_name')
environment_variables=$(get_option '.environment_variables')
stack=$(get_option '.stack')

logger::info "Executing $(logger::highlight "$command"): $current_app_name"

if [ ! -f "$manifest" ]; then
  logger::error "invalid payload (manifest is not a file: $manifest)"
  exit $E_MANIFEST_FILE_NOT_FOUND
fi

if [ -n "$environment_variables" ]; then
  cp "$manifest" "$manifest.original"
  for key in $(echo $environment_variables | jq -r 'keys[]'); do
    value=$(echo $environment_variables | jq -r --arg key "$key" '.[$key]')
    yq w -i "$manifest" -- "env.$key" "$value"
  done
fi

args=(-f "$manifest")
[ -n "$path" ]  && args+=(-p $path) # don't quote so we can support globbing
[ -n "$stack" ] && args+=(-s "$stack")

cf::target "$org" "$space"

if [ -n "$current_app_name" ]; then
  # autopilot (tested v0.0.2 - v0.0.6) doesn't like CF_TRACE=true
  CF_TRACE=false cf zero-downtime-push "$current_app_name" "${args[@]}"
else
  cf push "${args[@]}"
fi
