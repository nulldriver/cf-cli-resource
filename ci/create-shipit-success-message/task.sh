#!/bin/sh

version=$(cat version/version)

cd message

cat <<EOF >"message"
Announcing the release of cf-cli-resource v${version}!
Check out the release notes here:
  https://github.com/nulldriver/cf-cli-resource/releases/tag/v${version}
EOF
