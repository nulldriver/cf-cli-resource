# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.2/containers/alpine/.devcontainer/base.Dockerfile

# [Choice] Alpine version: 3.16, 3.15, 3.14, 3.13
ARG VARIANT="3.16"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-alpine-${VARIANT}

#
# Test dependencies
#
# gettext - provides the envsubst command used within create-user_from_file_spec.sh
# lastpass-cli - currently using as a centralized credential store for locally executing integration tests
# tar - Update to GNU tar to support fly execute (with BusyBox fly execute complains with "/bin/tar: unrecognized option: null")
# shellspec - shell testing framework used to execute tests in the spec folder
# fly - Concourse cli for managing pipelines
# credhub - Credential manager used to set pipeline secrets
#
RUN apk update \
    && apk add --no-cache gettext lastpass-cli tar

#
# Resource dependencies
#
# util-linux - provides uuidgen
RUN apk update \
    && apk add --no-cache util-linux

RUN curl -SL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && yq --version

ARG CF_CLI_6_VERSION=6.53.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_6_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_6_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_6_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_6_VERSION}/cf /usr/local/bin

ARG CF_CLI_7_VERSION=7.5.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_7_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_7_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_7_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_7_VERSION}/cf7 /usr/local/bin

ARG CF_CLI_8_VERSION=8.4.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_8_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_8_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_8_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_8_VERSION}/cf8 /usr/local/bin

ARG SHELLSPEC_VERSION=0.28.1
RUN mkdir -p /opt \
  && curl -SL "https://github.com/shellspec/shellspec/archive/${SHELLSPEC_VERSION}.tar.gz" \
    | tar -zxC /opt \
  && ln -s /opt/shellspec-${SHELLSPEC_VERSION}/shellspec /usr/local/bin/shellspec
