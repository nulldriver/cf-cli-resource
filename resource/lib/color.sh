
set -u

# Return if color lib already loaded.
test -n "${COLOR_RESET:-}" && return 0

# Reset
readonly COLOR_RESET=$'\033[0m'

# Regular Colors
readonly COLOR_FG_BLACK=$'\033[0;30m'
readonly COLOR_FG_RED=$'\033[0;31m'
readonly COLOR_FG_GREEN=$'\033[0;32m'
readonly COLOR_FG_YELLOW=$'\033[0;33m'
readonly COLOR_FG_BLUE=$'\033[0;34m'
readonly COLOR_FG_MAGENTA=$'\033[0;35m'
readonly COLOR_FG_CYAN=$'\033[0;36m'
readonly COLOR_FG_WHITE=$'\033[0;37m'

# Bold Colors
readonly COLOR_FG_BOLD_BLACK=$'\033[1;30m'
readonly COLOR_FG_BOLD_RED=$'\033[1;31m'
readonly COLOR_FG_BOLD_GREEN=$'\033[1;32m'
readonly COLOR_FG_BOLD_YELLOW=$'\033[1;33m'
readonly COLOR_FG_BOLD_BLUE=$'\033[1;34m'
readonly COLOR_FG_BOLD_MAGENTA=$'\033[1;35m'
readonly COLOR_FG_BOLD_CYAN=$'\033[1;36m'
readonly COLOR_FG_BOLD_WHITE=$'\033[1;37m'
