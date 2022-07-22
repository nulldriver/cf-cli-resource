FROM alpine:3.14

ADD resource/ /opt/resource/

# Install dependencies (gettext provides envsubst; util-linux provides uuidgen)
RUN apk add --no-cache --update-cache ca-certificates \
  bash \
  curl \
  gettext \
  jq \
  util-linux

# Install yaml cli
RUN curl -SL "https://github.com/mikefarah/yq/releases/download/v4.26.1/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install Cloud Foundry cli v6
ARG CF_CLI_6_VERSION=6.53.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_6_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_6_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_6_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_6_VERSION}/cf /usr/local/bin

# Install Cloud Foundry cli v7
ARG CF_CLI_7_VERSION=7.5.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_7_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_7_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_7_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_7_VERSION}/cf7 /usr/local/bin

# Install Cloud Foundry cli v8
ARG CF_CLI_8_VERSION=8.4.0
RUN mkdir -p /opt/cf-cli-${CF_CLI_8_VERSION} \
    && curl -SL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_8_VERSION}" \
      | tar -zxC /opt/cf-cli-${CF_CLI_8_VERSION} \
    && ln -s /opt/cf-cli-${CF_CLI_8_VERSION}/cf8 /usr/local/bin

# Install test dependencies
ARG SHELLSPEC_VERSION=0.28.1
RUN mkdir -p /opt \
  && curl -SL "https://github.com/shellspec/shellspec/archive/${SHELLSPEC_VERSION}.tar.gz" \
    | tar -zxC /opt \
  && ln -s /opt/shellspec-${SHELLSPEC_VERSION}/shellspec /usr/local/bin/shellspec
