#shellcheck shell=bash

# imported by "spec_helper.sh"

shellspec_syntax 'shellspec_matcher_json'

shellspec_matcher_json() {
  shellspec_matcher__match() {
    SHELLSPEC_EXPECT=$1
    [ "${SHELLSPEC_SUBJECT+x}" ] || return 1
    echo "$SHELLSPEC_SUBJECT" | jq -e "$SHELLSPEC_EXPECT" >/dev/null
  }

  # Message when the matcher fails with "should"
  shellspec_matcher__failure_message() {
    shellspec_putsn "expected: $1 match $2"
  }

  # Message when the matcher fails with "should not"
  shellspec_matcher__failure_message_when_negated() {
    shellspec_putsn "expected: $1 not match $2"
  }

  # checking for parameter count
  shellspec_syntax_param count [ $# -eq 1 ] || return 0
  shellspec_matcher_do_match "$@"
}
