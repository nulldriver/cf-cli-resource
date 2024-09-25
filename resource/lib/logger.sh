
set -eu
set -o pipefail

# Return if logger already loaded.
declare -f 'logger::set_level' >/dev/null && return 0

source "$(dirname "${BASH_SOURCE[0]}")/color.sh"

LOGGER_DEBUG=0
LOGGER_INFO=1
LOGGER_WARN=2
LOGGER_ERROR=3
LOGGER_NONE=4

# Set default log level
LOGGER_LEVEL=$LOGGER_INFO

logger::set_level() {
  local level=${1:?"Please provide a log level"}

  case "$level" in
    DEBUG)
      LOGGER_LEVEL=$LOGGER_DEBUG
      ;;
    INFO)
      LOGGER_LEVEL=$LOGGER_INFO
      ;;
    WARN)
      LOGGER_LEVEL=$LOGGER_WARN
      ;;
    ERROR)
      LOGGER_LEVEL=$LOGGER_ERROR
      ;;
    NONE)
      LOGGER_LEVEL=$LOGGER_NONE
      ;;
    *)
      echo "Unknown log level: $level"
      return 1
      ;;
  esac
}

logger::colorize() {
  local message=${1:?"Please provide a message"}

  if [ -n "${NO_COLOR:-}" ]; then
    message=$(echo "$message" | sed -E "s/#(black|red|green|yellow|blue|magenta|cyan|white|boldBlack|boldRed|boldGreen|boldYellow|boldBlue|boldMagenta|boldCyan|boldWhite)\(([^)]*)\)/\2/g")
  else
    message=$(echo "$message" | sed -E "s/#black\(([^)]*)\)/${COLOR_FG_BLACK}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#red\(([^)]*)\)/${COLOR_FG_RED}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#green\(([^)]*)\)/${COLOR_FG_GREEN}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#yellow\(([^)]*)\)/${COLOR_FG_YELLOW}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#blue\(([^)]*)\)/${COLOR_FG_BLUE}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#magenta\(([^)]*)\)/${COLOR_FG_MAGENTA}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#cyan\(([^)]*)\)/${COLOR_FG_CYAN}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#white\(([^)]*)\)/${COLOR_FG_WHITE}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldBlack\(([^)]*)\)/${COLOR_FG_BOLD_BLACK}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldRed\(([^)]*)\)/${COLOR_FG_BOLD_RED}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldGreen\(([^)]*)\)/${COLOR_FG_BOLD_GREEN}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldYellow\(([^)]*)\)/${COLOR_FG_BOLD_YELLOW}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldBlue\(([^)]*)\)/${COLOR_FG_BOLD_BLUE}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldMagenta\(([^)]*)\)/${COLOR_FG_BOLD_MAGENTA}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldCyan\(([^)]*)\)/${COLOR_FG_BOLD_CYAN}\1${COLOR_RESET}/g")
    message=$(echo "$message" | sed -E "s/#boldWhite\(([^)]*)\)/${COLOR_FG_BOLD_WHITE}\1${COLOR_RESET}/g")
  fi

  echo -e "$message"
}

logger::debug() {
  local message=${1:?"Please provide a message"}
  shift

  if [ $LOGGER_LEVEL -le $LOGGER_DEBUG ]; then
    printf "$(logger::colorize "#boldBlue(DEBUG) $message")\n" "$@"
  fi
}

logger::info() {
  local message=${1:?"Please provide a message"}
  shift

  if [ $LOGGER_LEVEL -le $LOGGER_INFO ]; then
    printf "$(logger::colorize "#boldGreen(INFO) $message")\n" "$@"
  fi
}

logger::warn() {
  local message=${1:?"Please provide a message"}
  shift

  if [ $LOGGER_LEVEL -le $LOGGER_WARN ]; then
    printf "$(logger::colorize "#boldYellow(WARN) $message")\n" "$@"
  fi
}

logger::error() {
  local message=${1:?"Please provide a message"}
  shift

  if [ $LOGGER_LEVEL -le $LOGGER_ERROR ]; then
    printf "$(logger::colorize "#boldRed(ERROR) $message")\n" "$@"
  fi
}
