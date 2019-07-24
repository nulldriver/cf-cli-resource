
set -eu

logger::export_colors() {
  C_NORMAL='\e[0m'
  C_FG_YELLOW='\e[33m'
  C_FG_RED='\e[91m'
  C_FG_GREEN='\e[92m'
}

logger::highlight() {
  logger::export_colors
  printf "${C_FG_YELLOW}${*}${C_NORMAL}"
}

logger::error() {
  logger::export_colors
  printf "${C_FG_RED}[ERROR]${C_NORMAL} %s\n" "$*"
}

logger::info() {
  logger::export_colors
  printf "${C_FG_GREEN}[INFO]${C_NORMAL} %s\n" "$*"
}
