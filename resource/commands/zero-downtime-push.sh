
manifest=$(get_option '.manifest')
current_app_name=$(get_option '.current_app_name')
show_app_log=$(get_option '.show_app_log')
path=$(get_option '.path')
environment_variables=$(get_option '.environment_variables')
vars=$(get_option '.vars')
vars_files=$(get_option '.vars_files')
docker_image=$(get_option '.docker_image')
docker_username=$(get_option '.docker_username')
docker_password=$(get_option '.docker_password')
no_start=$(get_option '.no_start')
stack=$(get_option '.stack')
staging_timeout=$(get_option '.staging_timeout' 0)
startup_timeout=$(get_option '.startup_timeout' 0)

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$current_app_name"

if [ ! -f "$manifest" ]; then
  logger::error "invalid payload (manifest is not a file: #yellow(%s))" "$manifest"
  exit $E_MANIFEST_FILE_NOT_FOUND
fi

if [ -n "$environment_variables" ]; then
  util::set_manifest_environment_variables "$manifest" "$environment_variables" "$current_app_name"
fi

args=()
[ -n "$current_app_name" ] && args+=("$current_app_name")
args+=(-f "$manifest")
[ -n "$path" ]             && args+=(-p $path) # don't quote so we can support globbing
[ -n "$docker_image" ]     && args+=(--docker-image "$docker_image")
[ -n "$docker_username" ]  && args+=(--docker-username "$docker_username")
[ -n "$docker_password" ]  && export CF_DOCKER_PASSWORD="$docker_password"
[ -n "$no_start" ]         && args+=(--no-start)
[ -n "$stack" ]            && args+=(-s "$stack")

for key in $(echo $vars | jq -r 'keys[]'); do
  value=$(echo $vars | jq -r --arg key "$key" '.[$key]')
  args+=(--var "$key=$value")
done

for vars_file in $(echo $vars_files | jq -r '.[]'); do
  if [ ! -f "$vars_file" ]; then
    logger::error "invalid payload (vars_file is not a file: #yellow(%s))" "$vars_file"
    exit 1
  fi
  args+=(--vars-file "$vars_file")
done

cf::target "$org" "$space"

[ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
[ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

if [ -n "$current_app_name" ] && cf::app_exists "$current_app_name"; then
  venerable_app_name="$current_app_name-venerable"
  cf::rename "$current_app_name" "$venerable_app_name"

  if ! cf::cf push "${args[@]}"; then
    if [ "true" == "$show_app_log" ]; then
      cf::logs "$current_app_name"
    fi

    logger::error "Error encountered during zero-downtime-push. Rolling back to current app."

    cf::delete "$current_app_name"
    cf::rename "$venerable_app_name" "$current_app_name"

    exit $E_ZERO_DOWNTIME_PUSH_FAILED
  fi

  cf::delete "$venerable_app_name"
else
  cf::cf push "${args[@]}"
fi

unset CF_STAGING_TIMEOUT
unset CF_STARTUP_TIMEOUT
unset CF_DOCKER_PASSWORD
