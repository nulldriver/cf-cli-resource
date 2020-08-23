
create_org() {
  local org=${1:?org null or not set}

  local params=$(jq -n \
    --arg org "$org" \
    '{
      command: "create-org",
      org: $org
    }'
  )

  put_with_params "$params"
}

delete_org() {
  local org=${1:?org null or not set}

  local params=$(jq -n \
    --arg org "$org" \
    '{
      command: "delete-org",
      org: $org
    }'
  )

  put_with_params "$params"
}

create_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    '{
      command: "create-space",
      org: $org,
      space: $space
    }'
  )

  put_with_params "$params"
}

delete_space() {
  local org=${1:?org null or not set}
  local space=${2:?space null or not set}

  local params=$(jq -n \
    --arg org "$org" \
    --arg space "$space" \
    '{
      command: "delete-space",
      org: $org,
      space: $space
    }'
  )

  put_with_params "$params"
}
