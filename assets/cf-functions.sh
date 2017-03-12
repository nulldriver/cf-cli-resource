
function cf_login() {
  local api_endpoint=$1
  local cf_user=$2
  local cf_pass=$3
  local skip_ssl_validation=$4

  local cf_skip_ssl_validation=""
  if [ "$skip_ssl_validation" = "true" ]; then
    cf_skip_ssl_validation="--skip-ssl-validation"
  fi

  cf api $api_endpoint $cf_skip_ssl_validation

  cf auth $cf_user $cf_pass
}

function cf_org_exists() {
  local org=$1
  cf curl /v2/organizations | jq -e --arg name "$org" '.resources[] | select(.entity.name == $name) | true' >/dev/null
}

function cf_target_org() {
  local org=$1
  local create=$2

  if [ "$create" = "true" ] && ! (cf orgs | grep -q ^$org$); then
    cf create-org $org
  fi

  cf target -o $org
}

function cf_delete_org() {
  cf delete-org -f "$1"
}

function cf_space_exists() {
  local org=$1
  cf curl /v2/spaces | jq -e --arg name "$org" '.resources[] | select(.entity.name == $name) | true' >/dev/null
}

function cf_target_space() {
  local space=$1
  local create=$2

  if [ "$create" = "true" ] && ! (cf spaces | grep -q ^$space$); then
    cf create-space $space
  fi

  cf target -s $space
}

function cf_delete_space() {
  local space=$1
  local org=$2

  if [ -n "$org" ]; then
    cf delete-space -f "$space" -o "$org"
  else
    cf delete-space -f "$space"
  fi
}

function cf_service_exists() {
  local service_instance=$1
  cf curl /v2/service_instances | jq -e --arg name "$service_instance" '.resources[] | select(.entity.name == $name) | true' >/dev/null
}

function cf_create_service() {
  local service=$1
  local plan=$2
  local service_instance=$3
  local configuration=$4
  local tags=$5
  cf create-service "$service" "$plan" "$service_instance" -c "$configuration" -t "$tags"
}

function cf_delete_service() {
  local service_instance=$1
  cf delete-service -f "$service_instance"
}

function cf_wait_for_service_instance() {
  local service_instance=$1
  local timeout=${2:-300}

  local guid=$(cf service $service_instance --guid)

  local start=$(date +%s)
  while true; do
    # Get the service instance info in JSON from CC and parse out the async 'state'
    local state=$(cf curl /v2/service_instances/$guid | jq -r .entity.last_operation.state)

    if [ "$state" = "succeeded" ]; then
      echo "Service $service_instance is ready"
      return
    elif [ "$state" = "failed" ]; then
      echo "Service $service_instance failed to provision"
      exit 1
    fi

    local now=$(date +%s)
    local time=$(($now - $start))
    if [[ "$time" -ge "$timeout" ]]; then
      echo "Timed out waiting for service instance to provision: $service_instance"
      exit 1
    fi
    sleep 5
  done
}
