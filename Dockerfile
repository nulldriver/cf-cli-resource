FROM alpine:3.11

ADD resource/ /opt/resource/
ADD itest/ /opt/itest/

# Install uuidgen
RUN apk add --no-cache ca-certificates curl bash jq util-linux

# Install Cloud Foundry cli v6
ADD https://packages.cloudfoundry.org/stable?release=linux64-binary&version=6.49.0 /tmp/cf-cli.tgz
RUN mkdir -p /usr/local/bin && \
  tar -xf /tmp/cf-cli.tgz -C /usr/local/bin && \
  cf --version && \
  rm -f /tmp/cf-cli.tgz

# Install Cloud Foundry cli v7
ADD https://packages.cloudfoundry.org/stable?release=linux64-binary&version=7.0.1 /tmp/cf7-cli.tgz
RUN mkdir -p /usr/local/bin /tmp/cf7-cli && \
  tar -xf /tmp/cf7-cli.tgz -C /tmp/cf7-cli && \
  install /tmp/cf7-cli/cf7 /usr/local/bin/cf7 && \
  cf7 --version && \
  rm -f /tmp/cf7-cli.tgz && \
  rm -rf /tmp/cf7-cli

# Install yaml cli
ADD https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 /tmp/yq_linux_amd64
RUN install /tmp/yq_linux_amd64 /usr/local/bin/yq && \
  yq --version && \
  rm -f /tmp/yq_linux_amd64
