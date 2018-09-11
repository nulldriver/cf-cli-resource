
set -eu
set -o pipefail

assert::success() {
  local command=${1:?command null or not set}
  set +e
  "$@"
  local status=$?
  if (( status != 0 )); then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf '  Command            :\e[91m%s\e[0m\n' "$( echo "$@")"
    printf '  Expected exit code :\e[91m%s\e[0m\n' "0"
    printf '  Actual exit code   :\e[91m%s\e[0m\n' "$status"
    return 1
  fi
}

assert::failure() {
  local command=${1:?command null or not set}
  set +e
  "$@"
  local status=$?
  if (( status == 0 )); then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf '  Command            :\e[91m%s\e[0m\n' "$( echo "$@")"
    printf '  Expected exit code :\e[91m%s\e[0m\n' "(non-zero)"
    printf '  Actual exit code   :\e[91m%s\e[0m\n' "$status"
    return 1
  fi
}

assert::equals() {
  local expected=$1
  local actual=$2

  if [ "$expected" != "$actual" ]; then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf '  Expected :\e[91m%s\e[0m\n' "$expected"
    printf '  Actual   :\e[91m%s\e[0m\n' "$actual"
    return 1
  fi
}

assert::matches() {
  local pattern=$1
  local actual=$2

  if ! echo "$actual" | grep -oEq "$pattern"; then
    printf '\e[91mAssertion Failure:\e[0m\n'
    printf '  Pattern :\e[91m%s\e[0m\n' "$pattern"
    printf '  Actual  :\e[91m%s\e[0m\n' "$actual"
    return 1
  fi
}
