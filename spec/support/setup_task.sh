#shellcheck shell=sh

set -euo pipefail

task "setup" "Setup Integration Test Dependencies"

setup_docker() {
    echo "Setup Docker test app"

    : "${CCR_DOCKER_PRIVATE_IMAGE:?}"
    : "${CCR_DOCKER_PRIVATE_SERVER:?}"
    : "${CCR_DOCKER_PRIVATE_USERNAME:?}"
    : "${CCR_DOCKER_PRIVATE_PASSWORD:?}"

    docker pull nulldriver/test-app
    docker tag nulldriver/test-app "$CCR_DOCKER_PRIVATE_IMAGE"
    docker login "$CCR_DOCKER_PRIVATE_SERVER" -u "$CCR_DOCKER_PRIVATE_USERNAME" -p "$CCR_DOCKER_PRIVATE_PASSWORD"
    docker push "$CCR_DOCKER_PRIVATE_IMAGE"
    docker logout "$CCR_DOCKER_PRIVATE_SERVER"
}

setup_task() {
  echo "Setup beginning..."

  setup_docker

  echo "Setup complete."
}
