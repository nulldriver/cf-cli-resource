
app_name=$(get_option '.app_name')
# backwards compatibility for deprecated 'buildpack' param (https://github.com/nulldriver/cf-cli-resource/issues/87)
buildpacks=$(get_option '.buildpacks' "$(util::json_array_push '[]' "$(get_option '.buildpack')")")
startup_command=$(get_option '.startup_command')
docker_image=$(get_option '.docker_image')
docker_username=$(get_option '.docker_username')
docker_password=$(get_option '.docker_password')
manifest=$(get_option '.manifest')
hostname=$(get_option '.hostname')
domain=$(get_option '.domain')
instances=$(get_option '.instances')
disk_quota=$(get_option '.disk_quota')
memory=$(get_option '.memory')
no_start=$(get_option '.no_start')
path=$(get_option '.path')
stack=$(get_option '.stack')
vars=$(get_option '.vars')
vars_files=$(get_option '.vars_files')
environment_variables=$(get_option '.environment_variables')
show_app_log=$(get_option '.show_app_log')
strategy=$(get_option '.strategy')
staging_timeout=$(get_option '.staging_timeout' 0)
startup_timeout=$(get_option '.startup_timeout' 0)

if [ -z "${manifest// }" ]; then
  manifest_file=
elif [ -f "$manifest" ]; then
  manifest_file=$manifest
elif util::is_json "$manifest"; then
  manifest_file="manifest-generated-from-pipeline.yml"
  logger::info "generating manifest from yaml: #yellow(%s)" "$manifest_file"
  echo "$(util::json_to_yaml "$manifest")" > "$manifest_file"
else
  logger::error "Invalid application manifest: must be valid file or yaml"
  exit 1
fi

if [ -n "$environment_variables" ]; then
  if [ -n "$manifest_file" ]; then
    logger::info "environment_variables: backing up original manifest to: %s.bak" "$manifest_file"
    cp "$manifest_file" "$manifest_file.bak"
  else
    manifest_file="manifest-generated-for-environment-variables.yml"
    logger::info "environment_variables: generating manifest: %s" "$manifest_file"
    touch "$manifest_file"
    if [ -n "$app_name" ]; then
      name=$app_name yq -n '.applications[0].name = env(name)' > "$manifest_file"
    fi
  fi
  logger::info "environment_variables: adding env to manifest: %s" "$manifest_file"
  util::set_manifest_environment_variables "$manifest_file" "$environment_variables" "$app_name"
fi

args=()
[ -n "$app_name" ]        && args+=("$app_name")
[ -n "$startup_command" ] && args+=(-c "$startup_command")
[ -n "$docker_image" ]    && args+=(--docker-image "$docker_image")
[ -n "$docker_username" ] && args+=(--docker-username "$docker_username")
[ -n "$docker_password" ] && export CF_DOCKER_PASSWORD="$docker_password"
[ -n "$manifest_file" ]   && args+=(-f "$manifest_file")
[ -n "$hostname" ]        && args+=(-n "$hostname")
[ -n "$domain" ]          && args+=(-d "$domain")
[ -n "$instances" ]       && args+=(-i "$instances")
[ -n "$disk_quota" ]      && args+=(-k "$disk_quota")
[ -n "$memory" ]          && args+=(-m "$memory")
[ -n "$no_start" ]        && args+=(--no-start)
[ -n "$path" ]            && args+=(-p $path) # don't quote so we can support globbing
[ -n "$stack" ]           && args+=(-s "$stack")
[ -n "$strategy" ]        && args+=(--strategy "$strategy")

for key in $(echo $vars | jq -r 'keys[]'); do
  value=$(echo $vars | jq -r --arg key "$key" '.[$key]')
  args+=(--var "$key=$value")
done

for buildpack in $(echo $buildpacks | jq -r '.[]'); do
  args+=(-b "$buildpack")
done

for vars_file in $(echo $vars_files | jq -r '.[]'); do
  args+=(--vars-file "$vars_file")
done

logger::info "Executing #magenta(%s) on app #yellow(%s)" "$command" "$app_name"

cf::target "$org" "$space"

[ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
[ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

set +e
cf::cf push "${args[@]:-}"
status=$?
set -e

if (( status != 0 )) && [ -n "$app_name" ] && [ "true" == "$show_app_log" ]; then
  status=$E_PUSH_FAILED_WITH_APP_LOGS_SHOWN
  cf::logs "$app_name"
fi

unset CF_STAGING_TIMEOUT
unset CF_STARTUP_TIMEOUT
unset CF_DOCKER_PASSWORD

exit $status
