#!/bin/bash

set -e -u

set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/cf-cli-tests.XXXXXX)

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    echo -e '\e[41;33;1m'"Failure encountered!"'\e[0m'
  fi
  rm -rf $TMPDIR_ROOT
}

trap on_exit EXIT

base_dir="$(cd "$(dirname $0)" ; pwd )"
if [ -d "$base_dir/../assets" ]; then
  resource_dir=$(cd $(dirname $0)/../assets && pwd)
else
  resource_dir=/opt/resource
fi

source $resource_dir/cf-functions.sh

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/cf-cli-tests.XXXXXX)

  echo -e 'running \e[33m'"$@"$'\e[0m...'
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

put_with_params() {
  jq -n \
  --arg api "$1" \
  --arg skip_cert_check "$2" \
  --arg username "$3" \
  --arg password "$4" \
  --argjson params "$5" \
  '{
    source: {
      api: $api,
      skip_cert_check: $skip_cert_check,
      username: $username,
      password: $password
    },
    params: $params
  }' | ${resource_dir}/out "$2" | tee /dev/stderr
}
