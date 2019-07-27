
set -eu
set -o pipefail

logger::export_colors() {
  C_NORMAL='\e[0m'
  C_FG_YELLOW='\e[33m'
  C_FG_RED='\e[91m'
  C_FG_GREEN='\e[92m'
}

logger::highlight() {
  logger::export_colors
  printf '%b%s%b' "$C_FG_YELLOW" "$*" "$C_NORMAL"
}

logger::error() {
  logger::export_colors
  printf '%b[ERROR]%b %s\n' "$C_FG_RED" "$C_NORMAL" "$*"
}

logger::info() {
  logger::export_colors
  printf '%b[INFO]%b %s\n' "$C_FG_GREEN" "$C_NORMAL" "$*"
}
