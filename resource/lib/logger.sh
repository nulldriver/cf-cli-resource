
set -eu
set -o pipefail

# Return if logger already loaded.
declare -f 'logger::export_colors' >/dev/null && return 0

logger::export_colors() {
  # Regular Colors
  BLACK=$'\033[0;30m'
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  MAGENTA=$'\033[0;35m'
  CYAN=$'\033[0;36m'
  WHITE=$'\033[0;37m'
  GRAY=$'\033[1;30m'  # Dark Gray

  # Bold Colors
  BOLD_RED=$'\033[1;31m'
  BOLD_GREEN=$'\033[1;32m'
  BOLD_YELLOW=$'\033[1;33m'
  BOLD_BLUE=$'\033[1;34m'
  BOLD_MAGENTA=$'\033[1;35m'
  BOLD_CYAN=$'\033[1;36m'
  BOLD_WHITE=$'\033[1;37m'

  # Reset
  RESET=$'\033[0m'
}

# Formats the message with the appropriate color.
# Usage:
#   logger::apply_colors "#red(This text) will be red."
# Arguments:
#   $1 - The message to colorize.
# Returns:
#   The colorized message.
logger::transform_colors() {
  local message=${1:?"Please provide a message"}

  if [ -n "${NO_COLOR:-}" ]; then
    # Remove color tags if color output is suppressed
    message=$(echo "$message" | sed -E "s/#(black|red|green|yellow|blue|magenta|cyan|white|gray|boldRed|boldGreen|boldYellow|boldBlue|boldMagenta|boldCyan|boldWhite)\(([^)]*)\)/\2/g")
  else
    logger::export_colors
    message=$(echo "$message" | sed -E "s/#black\(([^)]*)\)/${BLACK}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#red\(([^)]*)\)/${RED}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#green\(([^)]*)\)/${GREEN}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#yellow\(([^)]*)\)/${YELLOW}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#blue\(([^)]*)\)/${BLUE}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#magenta\(([^)]*)\)/${MAGENTA}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#cyan\(([^)]*)\)/${CYAN}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#white\(([^)]*)\)/${WHITE}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#gray\(([^)]*)\)/${GRAY}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldRed\(([^)]*)\)/${BOLD_RED}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldGreen\(([^)]*)\)/${BOLD_GREEN}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldYellow\(([^)]*)\)/${BOLD_YELLOW}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldBlue\(([^)]*)\)/${BOLD_BLUE}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldMagenta\(([^)]*)\)/${BOLD_MAGENTA}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldCyan\(([^)]*)\)/${BOLD_CYAN}\1${RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldWhite\(([^)]*)\)/${BOLD_WHITE}\1${RESET}/g")
  fi

  echo -e "$message"
}

# Logs an info message.
# Usage:
#   logger::info "This is an info message with a placeholder: %s" "additional info"
# Arguments:
#   $1 - The message to log, which can contain %s placeholders.
#   $@ - Additional arguments to replace the placeholders.
logger::info() {
  local message=${1:?"Please provide a message"}
  shift

  printf "$(logger::transform_colors "#green(INFO) $message")\n" "$@"
}

# Logs a warning message.
# Usage:
#   logger::warn "This is a warning message with a placeholder: %s" "additional info"
# Arguments:
#   $1 - The message to log, which can contain %s placeholders.
#   $@ - Additional arguments to replace the placeholders.
logger::warn() {
  local message=${1:?"Please provide a message"}
  shift

  printf "$(logger::transform_colors "#red(WARN) $message")\n" "$@"
}

# Logs an error message.
# Usage:
#   logger::error "This is an error message with a placeholder: %s" "additional info"
# Arguments:
#   $1 - The message to log, which can contain %s placeholders.
#   $@ - Additional arguments to replace the placeholders.
logger::error() {
  local message=${1:?"Please provide a message"}
  shift

  printf "$(logger::transform_colors "#boldRed(ERROR) $message")\n" "$@"
}
