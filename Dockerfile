FROM ubuntu:latest

ADD resource/ /opt/resource/

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (gettext-base provides envsubst)
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gettext-base jq uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

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
