
manifest=$(get_option '.manifest')
path=$(get_option '.path')
current_app_name=$(get_option '.current_app_name')
environment_variables=$(get_option '.environment_variables')
stack=$(get_option '.stack')
vars=$(get_option '.vars')
vars_files=$(get_option '.vars_files')

logger::info "Executing $(logger::highlight "$command"): $current_app_name"

if [ ! -f "$manifest" ]; then
  logger::error "invalid payload (manifest is not a file: $manifest)"
  exit $E_MANIFEST_FILE_NOT_FOUND
fi

if [ -n "$environment_variables" ]; then
  cf::set_manifest_environment_variables "$manifest" "$environment_variables"
fi

args=(-f "$manifest")
[ -n "$path" ]  && args+=(-p $path) # don't quote so we can support globbing
[ -n "$stack" ] && args+=(-s "$stack")

for key in $(echo $vars | jq -r 'keys[]'); do
  value=$(echo $vars | jq -r --arg key "$key" '.[$key]')
  args+=(--var "$key=$value")
done

for vars_file in $(echo $vars_files | jq -r '.[]'); do
  args+=(--vars-file "$vars_file")
done

cf::target "$org" "$space"

if [ -n "$current_app_name" ]; then

  venerable_app_name="$current_app_name-venerable"
  cf::rename "$current_app_name"  "$venerable_app_name"

  if ! cf::cf push "${args[@]}"; then
    output=$(cf::cf logs "$current_app_name" --recent)

    cf::cf delete -f "$current_app_name"
    cf::rename "$venerable_app_name" "$current_app_name"

    logger::error "$output"
    exit 1
  fi

  cf::cf delete -f "$venerable_app_name"

else
  cf::cf push "${args[@]}"
fi
