
push_app() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}
  local options=${4:-}

  local project="$FIXTURE/static-app"

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg app_name "$app_name" \
    --arg manifest "$project/manifest.yml" \
    '{
      command: "push",
      org: $org,
      space: $space,
      manifest: $manifest,
      vars: {
        app_name: $app_name
      }
    }'
  )

  if [ -n "$options" ]; then
    params=$(echo "$params" "$options" | jq -s 'add' )
  fi

  put_with_params "$params"
}

delete_app() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}
  local app_name=${3:?app_name null or not set}

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    --arg app_name "$app_name" \
    '{
      command: "delete",
      org: $org,
      space: $space,
      app_name: $app_name,
      delete_mapped_routes: "true"
    }'
  )

  put_with_params "$params"
}
