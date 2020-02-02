
app_name=$(echo $options | jq -r '.app_name //empty')
buildpack=$(echo $options | jq -r '.buildpack //empty')
startup_command=$(echo $options | jq -r '.startup_command //empty')
docker_image=$(echo $options | jq -r '.docker_image //empty')
docker_username=$(echo $options | jq -r '.docker_username //empty')
docker_password=$(echo $options | jq -r '.docker_password //empty')
manifest=$(echo $options | jq -r '.manifest //empty')
hostname=$(echo $options | jq -r '.hostname //empty')
domain=$(echo $options | jq -r '.domain //empty')
instances=$(echo $options | jq -r '.instances //empty')
disk_quota=$(echo $options | jq -r '.disk_quota //empty')
memory=$(echo $options | jq -r '.memory //empty')
no_start=$(echo $options | jq -r '.no_start //empty')
path=$(echo $options | jq -r '.path //empty')
stack=$(echo $options | jq -r '.stack //empty')
vars=$(echo $options | jq -r '.vars //empty')
vars_files=$(echo $options | jq -r '.vars_files //empty')
staging_timeout=$(echo $options | jq -r '.staging_timeout //0')
startup_timeout=$(echo $options | jq -r '.startup_timeout //0')

args=()
[ -n "$app_name" ]        && args+=("$app_name")
[ -n "$buildpack" ]       && args+=(-b "$buildpack")
[ -n "$startup_command" ] && args+=(-c "$startup_command")
[ -n "$docker_image" ]    && args+=(--docker-image "$docker_image")
[ -n "$docker_username" ] && args+=(--docker-username "$docker_username")
[ -n "$docker_password" ] && export CF_DOCKER_PASSWORD="$docker_password"
[ -n "$manifest" ]        && args+=(-f "$manifest")
[ -n "$hostname" ]        && args+=(-n "$hostname")
[ -n "$domain" ]          && args+=(-d "$domain")
[ -n "$instances" ]       && args+=(-i "$instances")
[ -n "$disk_quota" ]      && args+=(-k "$disk_quota")
[ -n "$memory" ]          && args+=(-m "$memory")
[ -n "$no_start" ]        && args+=(--no-start)
[ -n "$path" ]            && args+=(-p $path) # don't quote so we can support globbing
[ -n "$stack" ]           && args+=(-s "$stack")

for key in $(echo $vars | jq -r 'keys[]'); do
  value=$(echo $vars | jq -r --arg key "$key" '.[$key]')
  args+=(--var "$key=$value")
done

for vars_file in $(echo $vars_files | jq -r '.[]'); do
  args+=(--vars-file "$vars_file")
done

logger::info "Executing $(logger::highlight "$command"): $app_name"
cf::target "$org" "$space"

[ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
[ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

cf push "${args[@]}"

unset CF_STAGING_TIMEOUT
unset CF_STARTUP_TIMEOUT
if [ -n "$docker_password" ]; then
  unset CF_DOCKER_PASSWORD
fi
