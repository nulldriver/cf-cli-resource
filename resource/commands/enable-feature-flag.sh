
feature_name=$(get_option '.feature_name')

logger::info "Executing #magenta(%s) on feature #yellow(%s)" "$command" "$feature_name"

cf::enable_feature_flag "$feature_name"
