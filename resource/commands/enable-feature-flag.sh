
feature_name=$(echo $options | jq -r '.feature_name //empty')

logger::info "Executing $(logger::highlight "$command"): $feature_name"

cf::enable_feature_flag "$feature_name"
