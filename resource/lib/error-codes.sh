
# Return if error-codes already loaded.
test -n "${E_API_NOT_SET:-}" && return 0

declare -ri E_API_NOT_SET=10
declare -ri E_NEITHER_USERNAME_OR_CLIENT_ID_SET=11
declare -ri E_BOTH_USERNAME_AND_CLIENT_ID_SET=12
declare -ri E_PASSWORD_NOT_SET=13
declare -ri E_CLIENT_SECRET_NOT_SET=14
declare -ri E_COMMAND_FILE_NOT_FOUND=15
declare -ri E_MANIFEST_FILE_NOT_FOUND=16
declare -ri E_UNKNOWN_COMMAND=17
declare -ri E_PARAMS_NOT_SET=18
declare -ri E_COMMAND_NOT_SET=19
declare -ri E_NOT_LOGGED_IN=20
declare -ri E_CF_CLI_BINARY_NOT_FOUND=21
declare -ri E_UNSUPPORTED_CF_CLI_VERSION=22
declare -ri E_ZERO_DOWNTIME_PUSH_FAILED=23
declare -ri E_PUSH_FAILED_WITH_APP_LOGS_SHOWN=24
