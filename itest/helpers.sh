#!/bin/bash

set -eu
set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/cf-cli-tests.XXXXXX)

on_exit() {
  exitcode=$?
  if [ $exitcode != 0 ] ; then
    printf '\e[41;33;1mFailure encountered!\e[0m\n'
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
  export TMPDIR=$(mktemp -d $TMPDIR_ROOT/cf-cli-tests.XXXXXX)

  printf 'running \e[33m%s\e[0m...\n' "$@"
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

create_static_app() {
  local app_name=$1
  local working_dir=$2

  mkdir -p "$working_dir/static-app/content"

  echo "Hello" > "$working_dir/static-app/content/index.html"

  cat <<EOF >"$working_dir/static-app/manifest.yml"
---
applications:
- name: $app_name
  memory: 64M
  disk_quota: 64M
  instances: 1
  path: content
  buildpack: staticfile_buildpack
EOF
}

put_with_params() {
  local config=$1
  local working_dir=$2
  echo $config | $resource_dir/out "$working_dir" | tee /dev/stderr
}
