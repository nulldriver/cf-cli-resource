
set -eu
set -o pipefail

# Return if cf already loaded.
declare -f 'cf::cf' >/dev/null && return 0

base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

source "$base_dir/resource/lib/logger.sh"
source "$base_dir/resource/lib/error-codes.sh"

# Default to v6
: ${CCR_CF_CLI_VERSION:=6}

CF_CLI=
if [ "${CCR_CF_CLI_VERSION}" = "6" ]; then
  CF_CLI=cf
elif [ "${CCR_CF_CLI_VERSION}" = "7" ]; then
  CF_CLI=cf7
else
  logger::error "unsupported cf cli version: $CCR_CF_CLI_VERSION"
  exit $E_UNSUPPORTED_CF_CLI_VERSION
fi

if ! command -v "$CF_CLI" >/dev/null; then
  logger::error "cf cli v$CCR_CF_CLI_VERSION not found: Please ensure the v$CCR_CF_CLI_VERSION executable is named '$CF_CLI' and is available on the PATH"
  exit $E_CF_CLI_BINARY_NOT_FOUND
fi

function cf::cf() {
  "$CF_CLI" "$@"
}

function cf::is_cf6() {
  [[ "$(cf::cf version)" = "$CF_CLI version 6"* ]]
}

function cf::is_cf7() {
  [[ "$(cf::cf version)" = "$CF_CLI version 7"* ]]
}

function cf::curl() {
  CF_TRACE=false cf::cf curl --fail "$@"
}

function cf::is_logged_in() {
  cf::cf oauth-token >/dev/null 2>&1
}

function cf::api() {
  local url=${1:?url null or not set}
  local skip_ssl_validation=${2:-false}

  local args=("$url")
  [ "$skip_ssl_validation" = "true" ] && args+=(--skip-ssl-validation)
  cf::cf api "${args[@]}"
}

function cf::auth_user() {
  local username=${1:?username null or not set}
  local password=${2:?password null or not set}
  local origin=${3:-}

  local args=("$username" "$password")
  [ -n "$origin" ] && args+=(--origin "$origin")
  cf::cf auth "${args[@]}"
}

function cf::auth_client() {
  local client_id=${1:?client_id null or not set}
  local client_secret=${2:?client_secret null or not set}

  cf::cf auth "$client_id" "$client_secret" --client-credentials
}

function cf::target() {
  local org=${1:-}
  local space=${2:-}

  local args=()
  [ -n "$org" ]   && args+=(-o "$org")
  [ -n "$space" ] && args+=(-s "$space")

  cf::cf target "${args[@]}"
}

function cf::get_org_guid() {
  local org=${1:?org null or not set}
  # swallow "FAILED" stdout if org not found
  local org_guid=
  if org_guid=$(CF_TRACE=false cf::cf org "$org" --guid 2>/dev/null); then
    echo "$org_guid"
  fi
}

function cf::org_exists() {
  local org=${1:?org null or not set}
  [ -n "$(cf::get_org_guid "$org")" ]
}

function cf::create_org() {
  local org=${1:?org null or not set}
  cf::cf create-org "$org"
}

function cf::delete_org() {
  local org=${1:?org null or not set}
  cf::cf delete-org "$org" -f
}

function cf::get_space_guid() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  local org_guid="$(cf::get_org_guid "$org")"
  if [ -n "$org_guid" ]; then
    cf::curl "/v2/spaces" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$space;organization_guid:$org_guid" | jq -r '.resources[].metadata.guid'
  fi
}

function cf::space_exists() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  [ -n "$(cf::get_space_guid "$org" "$space")" ]
}

function cf::create_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  cf::cf create-space "$space" -o "$org"
}

function cf::delete_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  cf::cf delete-space "$space" -o "$org" -f
}

function cf::user_exists() {
  local username=${1:?username null or not set}
  local origin=${2:-uaa}

  local uaa_endpoint=$(jq -r '.UaaEndpoint' ${CF_HOME:-$HOME}/.cf/config.json)

  curl "${uaa_endpoint}/Users?attributes=id,userName&filter=userName+Eq+%22${username}%22+and+origin+Eq+%22${origin}%22" \
    --fail --silent --show-error \
    -H 'Accept: application/json' \
    -H "Authorization: $(cf::cf oauth-token)" \
    | jq -e '.totalResults == 1' >/dev/null
}

function cf::create_user_with_password() {
  local username=${1:?username null or not set}
  local password=${2:?password null or not set}
  cf::cf create-user "$username" "$password"
}

function cf::create_user_with_origin() {
  local username=${1:?username null or not set}
  local origin=${2:?origin null or not set}
  cf::cf create-user "$username" --origin "$origin"
}

function cf::create_users_from_file() {
  local file=${1:?file null or not set}

  if [ ! -f "$file" ]; then
    logger::error "file not found: $(logger::highlight "$file")"
    exit 1
  fi

  # First line is the header row, so skip it and start processing at line 2
  linenum=1
  sed 1d "$file" | while IFS=, read -r Username Password Org Space OrgManager BillingManager OrgAuditor SpaceManager SpaceDeveloper SpaceAuditor
  do
    (( linenum++ ))

    if [ -z "$Username" ]; then
      logger::warn "no Username specified, unable to process line number: $(logger::highlight "$linenum")"
      continue
    fi

    if [ -n "$Password" ]; then
      cf::cf create-user "$Username" "$Password"
    fi

    if [ -n "$Org" ]; then
      [ -n "$OrgManager" ]     && cf::cf set-org-role "$Username" "$Org" OrgManager || true
      [ -n "$BillingManager" ] && cf::cf set-org-role "$Username" "$Org" BillingManager || true
      [ -n "$OrgAuditor" ]     && cf::cf set-org-role "$Username" "$Org" OrgAuditor || true

      if [ -n "$Space" ]; then
        [ -n "$SpaceManager" ]   && cf::cf set-space-role "$Username" "$Org" "$Space" SpaceManager || true
        [ -n "$SpaceDeveloper" ] && cf::cf set-space-role "$Username" "$Org" "$Space" SpaceDeveloper || true
        [ -n "$SpaceAuditor" ]   && cf::cf set-space-role "$Username" "$Org" "$Space" SpaceAuditor || true
      fi
    fi
  done
}

function cf::delete_user() {
  local username=${1:?username null or not set}
  cf::cf delete-user -f "$username"
}

function cf::get_private_domain_guid() {
  local org=${1:?org null or not set}
  local domain=${2:?domain null or not set}

  local output
  if ! output=$(cf::curl "/v2/organizations/$(cf::get_org_guid "$org")/private_domains?inline-relations-depth=1&q=name:$domain"); then
    logger::error "$output"
    exit 1
  fi

  if echo $output | jq -e '.total_results == 0' >/dev/null; then
    return
  fi
  echo "$output" | jq -r '.resources[].metadata.guid'
}

function cf::get_shared_domain_guid() {
  local domain=${1:?domain null or not set}

  local output
  if ! output=$(cf::curl "/v2/shared_domains?inline-relations-depth=1&q=name:$domain") ; then
    logger::error "$output"
    exit 1
  fi

  if echo $output | jq -e '.total_results == 0' >/dev/null; then
    return
  fi
  echo "$output" | jq -r '.resources[].metadata.guid'
}

function cf::get_domain_guid() {
  local org=${1:?org null or not set}
  local domain=${2:?domain null or not set}

  local domain_guid=$(cf::get_private_domain_guid "$org" "$domain")
  if [ -z "$domain_guid" ]; then
    domain_guid=$(cf::get_shared_domain_guid "$domain")
  fi
  echo "$domain_guid"
}

function cf::check_route() {
  local org=${1:?org null or not set}
  local domain=${2:?domain null or not set}
  local host=${3:-}
  local path=${4:-}

  local domain_guid=$(cf::get_domain_guid "$org" "$domain")
  if [ -z "$domain_guid" ]; then
    return 1
  fi

  local url="/v2/routes/reserved/domain/$domain_guid"
  [ -n "$host" ] && url+="/host/$host"
  [ -n "$path" ] && url+="?path=%2F$path"

  grep -q '204 No Content' <(cf::curl "$url" -i)
}

cf::is_app_mapped_to_route() {
  local app_name=${1:?app_name null or not set}
  local route=${2:?route null or not set}

  local app_guid=$(cf::get_app_guid "$app_name")

  local output
  if ! output=$(cf::curl "/v2/apps/$app_guid/stats"); then
    echo "$output" && exit 1
  fi

  echo $output | jq -e --arg route "$route" '."0".stats | select(.uris[] == $route)' >/dev/null
}

cf::has_private_domain() {
  local org=${1:?org null or not set}
  local domain=${2:?domain null or not set}
  local org_guid=$(cf::get_org_guid "$org")
  cf::curl "/v2/organizations/$org_guid/private_domains?q=name:$domain" | jq -e '.total_results == 1' >/dev/null
}

function cf::create_domain() {
  local org=${1:?org null or not set}
  local domain=${2:?domain null or not set}
  cf::cf create-domain "$org" "$domain"
}

function cf::delete_domain() {
  local domain=${1:?domain null or not set}
  cf::cf delete-domain -f "$domain"
}

function cf::delete_route() {
  local domain=${1:?domain null or not set}
  local hostname=${2:-}
  local path=${3:-}

  local args=("$domain")
  [ -n "$hostname" ] && args+=(--hostname "$hostname")
  [ -n "$path" ]     && args+=(--path "$path")

  cf::cf delete-route -f "${args[@]}"
}

function cf::map_route() {
  local app_name=${1:?app_name null or not set}
  local domain=${2:?domain null or not set}
  local hostname=${3:-}
  local path=${4:-}

  local args=("$app_name" "$domain")
  [ -n "$hostname" ] && args+=(--hostname "$hostname")
  [ -n "$path" ]     && args+=(--path "$path")

  cf::cf map-route "${args[@]}"
}

function cf::unmap_route() {
  local app_name=${1:?app_name null or not set}
  local domain=${2:?domain null or not set}
  local hostname=${3:-}
  local path=${4:-}

  local args=("$app_name" "$domain")
  [ -n "$hostname" ] && args+=(--hostname "$hostname")
  [ -n "$path" ] && args+=(--path "$path")

  cf::cf unmap-route "${args[@]}"
}

# returns the app guid, otherwise null if not found
function cf::get_app_guid() {
  local app_name=${1:?app_name null or not set}
  CF_TRACE=false cf::cf app "$app_name" --guid
}

# returns the service instance guid, otherwise null if not found
function cf::get_service_instance_guid() {
  local service_instance=${1:?service_instance null or not set}
  # swallow "FAILED" stdout if service not found
  local service_instance_guid=
  if service_instance_guid=$(CF_TRACE=false cf::cf service "$service_instance" --guid 2>/dev/null); then
    echo "$service_instance_guid"
  fi
}

# returns true if service exists, otherwise false
function cf::service_exists() {
  local service_instance=${1:?service_instance null or not set}
  local service_instance_guid=$(cf::get_service_instance_guid "$service_instance")
  [ -n "$service_instance_guid" ]
}

function cf::get_user_provided_vcap_service() {
  local app_name=${1:?app_name null or not set}
  local service_instance=${2:?service_instance null or not set}

  cf::curl "/v2/apps/$(cf::get_app_guid "$app_name")/env" | jq --arg service_instance "$service_instance" '.system_env_json.VCAP_SERVICES."user-provided"[] | select(.name == $service_instance)'
}

function cf::create_or_update_user_provided_service_credentials() {
  local service_instance=${1:?service_instance null or not set}
  local credentials=${2:?credentials json null or not set}

  local json=$credentials
  if [ -f "$credentials" ]; then
    json=$(cat $credentials)
  fi

  # validate the json
  if echo "$json" | jq . 1>/dev/null 2>&1; then
    if cf::service_exists "$service_instance"; then
      cf::cf update-user-provided-service "$service_instance" -p "$json"
    else
      cf::cf create-user-provided-service "$service_instance" -p "$json"
    fi
  else
    logger::error 'invalid credentials payload (must be valid json string or json file)'
    exit 1
  fi
}

function cf::create_or_update_user_provided_service_syslog() {
  local service_instance=${1:?service_instance null or not set}
  local syslog_drain_url=${2:?syslog_drain_url null or not set}

  if cf::service_exists "$service_instance"; then
    cf::cf update-user-provided-service "$service_instance" -l "$syslog_drain_url"
  else
    cf::cf create-user-provided-service "$service_instance" -l "$syslog_drain_url"
  fi
}

function cf::create_or_update_user_provided_service_route() {
  local service_instance=${1:?service_instance null or not set}
  local route_service_url=${2:?route_service_url null or not set}

  if cf::service_exists "$service_instance"; then
    cf::cf update-user-provided-service "$service_instance" -r "$route_service_url"
  else
    cf::cf create-user-provided-service "$service_instance" -r "$route_service_url"
  fi
}

function cf::get_service_instance_tags() {
  local service_instance=${1:?service_instance null or not set}

  local output
  if ! output=$(cf::curl "/v2/service_instances/$(cf::get_service_instance_guid "$service_instance")"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r '.entity.tags | join(", ")'
}

function cf::get_service_instance_plan() {
  local service_instance=${1:?service_instance null or not set}

  local output
  if ! output=$(cf::curl "/v2/service_instances/$(cf::get_service_instance_guid "$service_instance")"); then
    logger::error "$output"
    exit 1
  fi

  local service_plan_url=$(echo $output | jq -r '.entity.service_plan_url')
  if ! output=$(cf::curl "$service_plan_url"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r '.entity.name'
}

function cf::create_service() {
  local service=${1:?service null or not set}
  local plan=${2:?plan null or not set}
  local service_instance=${3:?service_instance null or not set}
  local broker=${4:-}
  local configuration=${5:-}
  local tags=${6:-}

  local args=("$service" "$plan" "$service_instance")
  [ -n "$broker" ]        && args+=(-b "$broker")
  [ -n "$configuration" ] && args+=(-c "$configuration")
  [ -n "$tags" ]          && args+=(-t "$tags")

  cf::cf create-service "${args[@]}"
}

function cf::update_service() {
  local service_instance=${1:?service_instance null or not set}
  local plan=${2:-}
  local configuration=${3:-}
  local tags=${4:-}

  local args=("$service_instance")
  [ -n "$plan" ]          && args+=(-p "$plan")
  [ -n "$configuration" ] && args+=(-c "$configuration")
  [ -n "$tags" ]          && args+=(-t "$tags")

  cf::cf update-service "${args[@]}"
}

function cf::create_or_update_service() {
  local service=${1:?service null or not set}
  local plan=${2:?plan null or not set}
  local service_instance=${3:?service_instance null or not set}
  local broker=${4:-}
  local configuration=${5:-}
  local tags=${6:-}

  if cf::service_exists "$service_instance"; then
    cf::update_service "$service_instance" "$plan" "$configuration" "$tags"
  else
    cf::create_service "$service" "$plan" "$service_instance" "$broker" "$configuration" "$tags"
  fi
}

function cf::share_service() {
  local service_instance=${1:?service_instance null or not set}
  local other_space=${2:?other_space null or not set}
  local other_org=${3:-}

  local args=("$service_instance" -s "$other_space")
  [ -n "$other_org" ] && args+=(-o "$other_org")

  cf::cf share-service "${args[@]}"
}

function cf::unshare_service() {
  local service_instance=${1:?service_instance null or not set}
  local other_space=${2:?other_space null or not set}
  local other_org=${3:-}

  local args=("$service_instance" -s "$other_space")
  [ -n "$other_org" ] && args+=(-o "$other_org")

  cf::cf unshare-service -f "${args[@]}"
}

function cf::delete_service() {
  local service_instance=${1:?service_instance null or not set}
  cf::cf delete-service "$service_instance" -f
}

function cf::wait_for_service_instance() {
  local service_instance=${1:?service_instance null or not set}
  local timeout=${2:-600}

  local guid=$(cf::get_service_instance_guid "$service_instance")
  if [ -z "$guid" ]; then
    logger::error "Service instance does not exist: $(logger::highlight "$service_instance")"
    exit 1
  fi

  local start=$(date +%s)

  logger::info "Waiting for service: $(logger::highlight "$service_instance")"
  while true; do
    # Get the service instance info in JSON from CC and parse out the async 'state'
    local state=$(cf::curl "/v2/service_instances/$guid" | jq -r .entity.last_operation.state)

    if [ "$state" = "succeeded" ]; then
      logger::info "Service is ready: $(logger::highlight "$service_instance")"
      return
    elif [ "$state" = "failed" ]; then
      local description=$(logger::highlight "$(cf::curl "/v2/service_instances/$guid" | jq -r .entity.last_operation.description)")
      logger::error "Failed to provision service: $(logger::highlight "$service_instance"), error: $(logger::highlight "$description")"
      exit 1
    fi

    local now=$(date +%s)
    local time=$(($now - $start))
    if [[ "$time" -ge "$timeout" ]]; then
      logger::error "Timed out waiting for service instance to provision: $(logger::highlight "$service_instance")"
      exit 1
    fi
    sleep 5
  done
}

function cf::wait_for_delete_service_instance() {
  local service_instance=${1:?service_instance null or not set}
  local timeout=${2:-600}

  local start=$(date +%s)

  logger::info "Waiting for service deletion: $(logger::highlight "$service_instance")"
  while true; do
    if ! (cf::service_exists "$service_instance"); then
      logger::info "Service deleted: $(logger::highlight "$service_instance")"
      return
    fi

    local now=$(date +%s)
    local time=$(($now - $start))
    if [[ "$time" -ge "$timeout" ]]; then
      logger::error "Timed out waiting for service instance to delete: $(logger::highlight "$service_instance")"
      exit 1
    fi
    sleep 5
  done
}

function cf::create_service_key() {
  local service_instance=${1:?service_instance null or not set}
  local service_key=${2:?service_key null or not set}
  local configuration=${3:-}

  local args=("$service_instance" "$service_key")
  [ -n "$configuration" ] && args+=(-c "$configuration")

  cf::cf create-service-key "${args[@]}"
}

function cf::delete_service_key() {
  local service_instance=${1:?service_instance null or not set}
  local service_key=${2:?service_key null or not set}
  cf::cf delete-service-key "$service_instance" "$service_key" -f
}

function cf::get_service_key_guid() {
  local service_instance=${1:?service_instance null or not set}
  local service_key=${2:?service_key null or not set}

  # swallow "FAILED" stdout if service_instance not found
  local guid=
  if guid=$(CF_TRACE=false cf::cf service-key "$service_instance" "$service_key" --guid 2>/dev/null); then
    # cf v6.42.0 returns an empty string with newline if the service key does not exist
    if [ -n "$guid" ]; then
      echo "$guid"
    fi
  fi
}

function cf::service_key_exists() {
  local service_instance=${1:?service_instance null or not set}
  local service_key=${2:?service_key null or not set}

  [ -n "$(cf::get_service_key_guid "$service_instance" "$service_key")" ]
}

function cf::create_or_update_service_broker() {
  local service_broker=${1:?service_broker null or not set}
  local username=${2:?username null or not set}
  local password=${3:?password null or not set}
  local url=${4:?broker_url null or not set}
  local is_space_scoped=${5:-}

  local space_scoped=
  if [ "$is_space_scoped" = "true" ]; then
    space_scoped="--space-scoped"
  fi

  if cf::service_broker_exists "$service_broker"; then
    cf::cf update-service-broker "$service_broker" "$username" "$password" "$url"
  else
    cf::cf create-service-broker "$service_broker" "$username" "$password" "$url" $space_scoped
  fi
}

function cf::delete_service_broker() {
  local service_broker=${1:?service_broker null or not set}
  cf::cf delete-service-broker "$service_broker" -f
}

function cf::bind_service() {
  local app_name=${1:?app_name null or not set}
  local service_instance=${2:?service_instance null or not set}
  local configuration=${3:-}
  local binding_name=${4:-}

  local args=("$app_name" "$service_instance")
  [ -n "$configuration" ] && args+=(-c "$configuration")
  [ -n "$binding_name" ] && args+=(--binding-name "$binding_name")

  cf::cf bind-service "${args[@]}"
}

function cf::unbind_service() {
  local app_name=${1:?app_name null or not set}
  local service_instance=${2:?service_instance null or not set}
  cf::cf unbind-service "$app_name" "$service_instance"
}

function cf::is_app_bound_to_service() {
  local app_name=${1:?app_name null or not set}
  local service_instance=${2:?service_instance null or not set}
  local app_guid=$(cf::get_app_guid "$app_name")
  local si_guid=$(CF_TRACE=false cf::cf service "$service_instance" --guid)
  cf::curl "/v2/apps/$app_guid/service_bindings" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=service_instance_guid:$si_guid" | jq -e '.total_results == 1' >/dev/null
}

function cf::is_app_bound_to_route_service() {
  local app_name=${1:?app_name null or not set}
  local service_instance=${2:?service_instance null or not set}
  local org=${3:?org null or not set}
  local space=${4:?space null or not set}
  local path=${5:-}

  local space_guid=$(cf::get_space_guid "$org" "$space")
  cf::curl "/v2/spaces/$space_guid/routes?inline-relations-depth=1" | jq -e \
    --arg service_instance "$service_instance" \
    --arg app_name "$app_name" \
    --arg path "$path" \
    '.resources[].entity | select (.service_instance.entity.name == $service_instance and .apps[].entity.name == $app_name and .path == $path) | true' >/dev/null
}

function cf::get_env() {
  local app_name=${1:?app_name null or not set}
  local env_var_name=${2:?env_var_name null or not set}

  local output
  if ! output=$(cf::curl "/v2/apps/$(cf::get_app_guid "$app_name")/env"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r --arg key "$env_var_name" '.environment_json[$key] // empty'
}

function cf::has_env() {
  local app_name=${1:?app_name null or not set}
  local env_var_name=${2:?env_var_name null or not set}
  local env_var_value=${3:?env_var_value null or not set}

  local output
  if ! output=$(cf::curl "/v2/apps/$(cf::get_app_guid "$app_name")/env"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -e --arg key "$env_var_name" --arg value "$env_var_value" '.environment_json[$key] == $value' >/dev/null
}

function cf::start() {
  local app_name=${1:?app_name null or not set}
  local staging_timeout=${2:-0}
  local startup_timeout=${3:-0}

  [ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
  [ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

  cf::cf start "$app_name"

  unset CF_STAGING_TIMEOUT
  unset CF_STARTUP_TIMEOUT
}

function cf::stop() {
  local app_name=${1:?app_name null or not set}

  cf::cf stop "$app_name"
}

function cf::restart() {
  local app_name=${1:?app_name null or not set}
  local staging_timeout=${2:-0}
  local startup_timeout=${3:-0}

  [ "$staging_timeout" -gt "0" ] && export CF_STAGING_TIMEOUT=$staging_timeout
  [ "$startup_timeout" -gt "0" ] && export CF_STARTUP_TIMEOUT=$startup_timeout

  cf::cf restart "$app_name"

  unset CF_STAGING_TIMEOUT
  unset CF_STARTUP_TIMEOUT
}

function cf::delete() {
  local app_name=${1:?app_name null or not set}
  local delete_mapped_routes=${2:-}

  if [ -n "$delete_mapped_routes" ]; then
    cf::cf delete "$app_name" -f -r
  else
    cf::cf delete "$app_name" -f
  fi
}

function cf::rename() {
  local app_name=${1:?app_name null or not set}
  local new_app_name=${2:?new_app_name null or not set}

  cf::cf rename "$app_name" "$new_app_name"
}

function cf::network_policy_exists() {
  local source_app=${1:?source_app null or not set}
  local destination_app=${2:?destination_app null or not set}
  local protocol=${3=tcp}
  local port=${4:=8080}

  local output=
  if ! output=$(CF_TRACE=false cf::cf network-policies --source "$source_app"); then
    logger::error "$output"
    exit 1
  fi
  echo "$output" | grep "$destination_app" | grep "$protocol" | grep -q "$port"
}

# very loose match on some "task name" (or command...) in the cf tasks output
function cf::was_task_run() {
  local app_name=${1:?app_name null or not set}
  local task_name=${2:?task_name null or not set}
  CF_TRACE=false cf::cf tasks "$app_name" | grep "$task_name" >/dev/null
}

function cf::is_app_started() {
  local app_name=${1:?app_name null or not set}
  local guid=
  if ! guid=$(cf::get_app_guid "$app_name"); then
    local status=${PIPESTATUS[0]}
    logger::error "$guid"
    exit $status
  fi
  local output=
  if ! output=$(cf::curl "/v2/apps/$guid/summary"); then
    local status=${PIPESTATUS[0]}
    logger::error "$guid"
    exit $status
  fi
  echo $output | jq -e '.instances == .running_instances' >/dev/null
}

function cf::is_app_stopped() {
  local app_name=${1:?app_name null or not set}
  local guid=$(cf::get_app_guid "$app_name")
  cf::curl "/v2/apps/$guid" | jq -e '.entity.state == "STOPPED"' >/dev/null
}

function cf::app_exists() {
  local app_name=${1:?app_name null or not set}
  cf::get_app_guid "$app_name" >/dev/null 2>&1
}

function cf::get_app_instances() {
  local app_name=${1:?app_name null or not set}
  local guid=$(cf::get_app_guid "$app_name")
  cf::curl "/v2/apps/$guid" | jq -r '.entity.instances'
}

function cf::get_app_memory() {
  local app_name=${1:?app_name null or not set}
  local guid=$(cf::get_app_guid "$app_name")
  cf::curl "/v2/apps/$guid" | jq -r '.entity.memory'
}

function cf::get_app_disk_quota() {
  local app_name=${1:?app_name null or not set}
  local guid=$(cf::get_app_guid "$app_name")
  cf::curl "/v2/apps/$guid" | jq -r '.entity.disk_quota'
}

function cf::get_app_stack() {
  local app_name=${1:?app_name null or not set}

  local output
  if ! output=$(cf::curl "/v2/apps/$(cf::get_app_guid "$app_name")"); then
    logger::error "$output"
    exit 1
  fi

  if ! output=$(cf::curl "$(echo $output | jq -r '.entity.stack_url')"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r '.entity.name'
}

function cf::get_app_buildpacks() {
  local app_name=${1:?app_name null or not set}

  local output
  if ! output=$(cf::curl "/v3/apps/$(cf::get_app_guid "$app_name")"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r '.lifecycle | select(.type == "buildpack") | .data.buildpacks | join(",")'
}

function cf::scale() {
  local app_name=${1:?app_name null or not set}
  local instances=${2:-}
  local memory=${3:-}
  local disk_quota=${4:-}

  local args=(-f "$app_name")
  [ -n "$instances" ] && args+=(-i "$instances")
  [ -n "$memory" ] && args+=(-m "$memory")
  [ -n "$disk_quota" ] && args+=(-k "$disk_quota")

  cf::cf scale "${args[@]}"
}

function cf::get_app_startup_command() {
  local app_name=${1:?app_name null or not set}

  local output
  if ! output=$(cf::curl "/v2/apps/$(cf::get_app_guid "$app_name")/summary"); then
    logger::error "$output"
    exit 1
  fi

  echo $output | jq -r '.command // empty'
}

function cf::logs() {
  local app_name=${1:?app_name null or not set}

  cf::cf logs "$app_name" --recent
}

function cf::service_broker_exists() {
  local service_broker=${1:?service_broker null or not set}
  cf::curl /v2/service_brokers | jq -e --arg name "$service_broker" '.resources[] | select(.entity.name == $name) | true' >/dev/null
}

function cf::is_marketplace_service_available() {
  local service_name=${1:?service_name null or not set}
  local plan=${2:-'.*'}
  local orgs=${3:-'.*'}

  # use subshell as alternative to pipe to get around SIGPIPE signal when piping to grep -q
  grep -qE "($service_name)\s+($plan)\s+(all|limited)\s+($orgs)" <(CF_TRACE=false cf::cf service-access -e "$service_name")
}

function cf::enable_feature_flag() {
  local feature_name=${1:?feature_name null or not set}
  CF_TRACE=false cf::cf enable-feature-flag "$feature_name"
}

function cf::disable_feature_flag() {
  local feature_name=${1:?feature_name null or not set}
  CF_TRACE=false cf::cf disable-feature-flag "$feature_name"
}

function cf::is_feature_flag_enabled() {
  local feature_flag=${1:?feature_flag null or not set}
  CF_TRACE=false cf::cf feature-flags | grep "$feature_flag" | grep -q enabled
}

function cf::is_feature_flag_disabled() {
  local feature_flag=${1:?feature_flag null or not set}
  CF_TRACE=false cf::cf feature-flags | grep "$feature_flag" | grep -q disabled
}

function cf::has_buildpack() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -e '.total_results == 1' >/dev/null
}

function cf::is_buildpack_enabled() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -e '.resources[].entity.enabled == true' >/dev/null
}

function cf::is_buildpack_locked() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -e '.resources[].entity.locked == true' >/dev/null
}

function cf::get_buildpack_stack() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -r '.resources[].entity.stack'
}

function cf::get_buildpack_filename() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -r '.resources[].entity.filename'
}

function cf::get_buildpack_position() {
  local buildpack=${1:?buildpack null or not set}
  cf::curl "/v2/buildpacks" -X GET -H "Content-Type: application/x-www-form-urlencoded" -d "q=name:$buildpack" | jq -r '.resources[].entity.position'
}

function cf::get_buildpack_max_position() {
  cf::curl "/v2/buildpacks" | jq -r '[.resources[].entity.position] | max'
}

function cf::set_manifest_environment_variables() (
  local manifest=${1:?manifest null or not set}
  local environment_variables=${2:?environment_variables null or not set}
  local app_name=${3:-}

  get_keys() {
    echo "$environment_variables" | jq -r 'keys[]'
  }

  get_value() {
    local key=${1:?key null or not set}
    echo "$environment_variables" | jq -r --arg key "$key" '.[$key]'
  }

  has_app_name() {
    [ -n "$app_name" ] && [ -n "$(yq read "$manifest" "applications.name==$app_name")" ]
  }

  has_one_app() {
    [ "1" == "$(yq read "$manifest" "applications" -l)" ]
  }

  for key in $(get_keys); do
    if has_app_name; then
      yq write -i "$manifest" -- "applications(name==$app_name).env.$key" "$(get_value "$key")"
    elif has_one_app; then
      yq write -i "$manifest" -- "applications[0].env.$key" "$(get_value "$key")"
    else
      yq write -i "$manifest" -- "env.$key" "$(get_value "$key")"
    fi
  done
)
