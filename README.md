# cf cli Concourse Resource

An output only resource capable of running lots of Cloud Foundry cli commands.

|            | Status |
| ---------- | ------ |
| build      | [![build](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/build/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/build/builds/latest) |
| v6 tests   | [![v6 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v6/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v6/builds/latest) |
| v7 tests   | [![v7 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v7/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v7/builds/latest) |
| v8 tests   | [![v8 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v8/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v8/builds/latest) |
| image scan | [![image scan](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/scan-image/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/scan-image/builds/latest) |
| docker     | [![Docker Pulls](https://img.shields.io/docker/pulls/nulldriver/cf-cli-resource.svg)](https://hub.docker.com/r/nulldriver/cf-cli-resource/) |

## Source Configuration

Base configuration parameters:

| Params            | Usage      | Description
| ---               | ---        | ---
| `api`             | *Required* | The address of the Cloud Controller in the Cloud Foundry deployment.
| `skip_cert_check` | *Optional* | Check the validity of the CF SSL cert. Defaults to `false`.
| `org`             | *Optional* | Sets the default organization to target (can be overridden in the params config).
| `space`           | *Optional* | Sets the default space to target (can be overridden in the params config).
| `cf_color`        | *Optional* | Set to `false` to not colorize cf output (can be overridden in the params config).
| `cf_dial_timeout` | *Optional* | Max wait time to establish a connection, including name resolution, in seconds (can be overridden in the params config).
| `cf_trace`        | *Optional* | Set to `true` to print cf API request diagnostics to stdout (can be overridden in the params config).

Supported cf cli versions:

| Params            | Usage      | Description
| ---               | ---        | ---
| `cf_cli_version`  | *Optional* | The major version of the [cf cli](https://github.com/cloudfoundry/cli) to use. Supported values: `6`, `7`, `8` (defaults to `6`)

Authentication is supported by either using `username` and `password`:

| Params            | Usage      | Description
| ---               | ---        | ---
| `username`        | *Required* | The username used to authenticate.
| `password`        | *Required* | The password used to authenticate.
| `origin`          | *Optional* | The identity provider to be used for authentication

...or using `client_id` and `client_secret`:

| Params            | Usage      | Description
| ---               | ---        | ---
| `client_id`       | *Required* | The client id used to authenticate.
| `client_secret`   | *Required* | The client secret used to authenticate.

```yaml
resource_types:
  - name: cf-cli-resource
    type: registry-image
    source:
      repository: nulldriver/cf-cli-resource
      tag: latest

resources:
  - name: cloud-foundry
    type: cf-cli-resource
    source:
      api: https://api.example.com
      username: name@example.com
      password: my password
      cf_cli_version: 8
```

## Multiple Command Syntax

This resource is capable of running single commands in separate `put` steps:

```yaml
- put: cloud-foundry
  params:
    command: create-org
    org: myorg
- put: cloud-foundry
  params:
    command: create-space
    org: myorg
    space: myspace
```

_or_ they can be combined in a single `put` step:

```yaml
- put: cloud-foundry
  params:
    commands:
      - command: create-org
        org: myorg
      - command: create-space
        org: myorg
        space: myspace
```

And, of course, if you have your `org` and `space` defined in the `source` config, it gets even more concise:

```yaml
- put: cloud-foundry
  params:
    commands:
      - command: create-org
      - command: create-space
```

## CF_HOME

The standard way to authenticate the `cf-cli-resource` with a target Cloud Foundry environment is to either use `username` **and** `password` *or* `client_id` **and** `client_secret`, which will save a `$CF_HOME/.cf/config.json` file containing the API endpoint, and access token. For some pipeline workflows, it is necessary to authenticate using alternative methods and then supply the pre-configured `config.json` to the `cf-cli-resource`.

> See [examples/cf_home-auth/pipeline.yml](examples/cf_home-auth/pipeline.yml) for a full example

```yaml
resources:
  - name: cloud-foundry
    type: cf-cli-resource

jobs:
  - name: deploy
    plan:
      - get: my-repo
      - task: authenticate
        file: my-repo/some-script-that-authenticates-and-creates-a-cf-config-json.yml
      - put: cloud-foundry
        params:
          cf_home: authenticate-task-output
          commands:
            - command: push
              path: my-repo/myapp
              manifest: my-repo/manifest.yml
```

## Command via file input

This resource supports file inputs. This allows the pipeline to parameterize and generate commands during pipeline execution.

| Params         | Usage      | CLI Version | Description
| ---            | ---        | ---         | ---
| `command_file` | *Optional* | All         | Contains path to a YAML file that contains the same fields as `params`; including `command` or `commands`. If used, this resource uses only the configuration listed in this file. All other configurations specified in the `params` section will be ignored. The `command_file` field (if exists) is ignored within the content of the file itself.

```yaml
- task: configure
  config:
    platform: linux
    image_resource:
      type: docker-image
      source:
        repository: ubuntu
    run:
      path: bash
      args:
        - -excl
        - |-
          cat > cf_command/params.yml <<EOF
          command: delete
          app_name: myapp
          delete_mapped_routes: true
          EOF
    outputs:
      - name: cf_command
- put: cloud-foundry
  params:
    command: delete
    command_file: cf_command/params.yml
```

## Commands

### `create-org`

Create an org

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to create (*Optional if set in the source config*)

```yaml
- put: cloud-foundry
  params:
    command: create-org
    org: myorg
```

### `delete-org`

Delete an org

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to delete (*Optional if set in the source config*)

```yaml
- put: cloud-foundry
  params:
    command: delete-org
    org: myorg
```

### `create-space`

Create a space

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to create (*Optional if set in the source config*)

```yaml
- put: cloud-foundry
  params:
    command: create-space
    org: myorg
    space: myspace
```

### `delete-space`

Delete a space

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to delete (*Optional if set in the source config*)

```yaml
- put: cloud-foundry
  params:
    command: delete-space
    org: myorg
    space: myspace
```

### `create-private-domain`

Create a private domain for a specific org

> Alias: `create-domain`

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | The domain to add to the organization

```yaml
- put: cloud-foundry
  params:
    command: create-private-domain
    org: myorg
    domain: example.com
```

### `delete-private-domain`

Delete a private domain

> Alias: `delete-domain`

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | The domain to delete

```yaml
- put: cloud-foundry
  params:
    command: delete-private-domain
    domain: example.com
```

### `create-shared-domain`

Create a domain that can be used by all orgs (admin-only)

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `domain`           | *Required* | All         | The shared domain to create
| `internal`         | *Optional* | All         | (boolean) Applications that use internal routes communicate directly on the container network

```yaml
- put: cloud-foundry
  params:
    command: create-shared-domain
    domain: example.com
```

### `delete-shared-domain`

Delete a shared domain

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | The shared domain to create

```yaml
- put: cloud-foundry
  params:
    command: delete-shared-domain
    org: myorg
    domain: example.com
```

### `create-route`

Create a route for later use

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `other_space`      | *Optional* | 6           | The space for the route (*Defaults to `space`*)
| `domain`           | *Required* | All         | Domain for the HTTP route
| `hostname`         | *Optional* | All         | Hostname for the HTTP route (required for shared domains)
| `path`             | *Optional* | All         | Path for the HTTP route

```yaml
- put: cloud-foundry
  params:
    command: create-route
    domain: example.com
    hostname: myhost
    path: foo
```

### `map-route`

Map a route to an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The application to map the route to
| `domain`           | *Required* | All         | The domain to map to the application
| `hostname`         | *Optional* | All         | Hostname for the HTTP route (required for shared domains)
| `path`             | *Optional* | All         | Path for the HTTP route
| `app_protocol`     | *Optional* | 8           | [Beta flag, subject to change] Protocol for the route destination (default: http1). Only applied to HTTP routes

```yaml
- put: cloud-foundry
  params:
    command: map-route
    app_name: myapp
    domain: example.com
    hostname: myhost
    path: foo
```

### `unmap-route`

Remove a route from an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The application to map the route to
| `domain`           | *Required* | All         | The domain to unmap from the application
| `hostname`         | *Optional* | All         | Hostname used to identify the HTTP route
| `path`             | *Optional* | All         | Path used to identify the HTTP route

```yaml
- put: cloud-foundry
  params:
    command: unmap-route
    app_name: myapp
    domain: example.com
    hostname: myhost
    path: foo
```

### `delete-route`

Delete a route

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | Domain used to identify the HTTP route
| `hostname`         | *Optional* | All         | Hostname used to identify the HTTP route
| `path`             | *Optional* | All         | Path used to identify the HTTP route

```yaml
- put: cloud-foundry
  params:
    command: delete-route
    domain: example.com
    hostname: myhost
    path: foo
```

### `create-user`

Create a new user

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `username`         | *Required* | All         | The user to create
| `password`         | *Optional* | All         | The password (*must specify either `password` or `origin`*)
| `origin`           | *Optional* | All         | The authentication origin (e.g. ldap, provider-alias) (*must specify either `password` or `origin`*)

Create a user with credentials:

```yaml
- put: cloud-foundry
  params:
    command: create-user
    username: j.smith@example.com
    password: S3cr3t
```

Create an LDAP user:

```yaml
- put: cloud-foundry
  params:
    command: create-user
    username: j.smith@example.com
    origin: ldap
```

### `create-users-from-file`

Bulk create users from a csv file

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `file`             | *Required* | All         | The csv file containing the users

```yaml
- put: cloud-foundry
  params:
    command: create-users-from-file
    file: somepath/users.csv
```

The format of the bulk load file:

| Username | Password | Org  | Space | OrgManager | BillingManager | OrgAuditor | SpaceManager | SpaceDeveloper | SpaceAuditor |
| -------- | -------- | ---- | ----- | ---------- | -------------- | ---------- | ------------ | -------------- | ------------ |
| user1    | S3cr3t   | org1 | dev   | x          | x              | x          | x            | x              | x            |
| user2    |          | org2 | dev   |            | x              | x          |              | x              | x            |
| user3    | S3cr3t   | org3 | dev   |            |                | x          |              |                | x            |
| user3    | S3cr3t   | org3 | test  |            |                | x          |              |                | x            |

Notes:

- The file must include the header row
- The file must be in comma separated value format
- You can specify the user more than once to assign multiple orgs/spaces
- If you omit the `Org`, no org or space roles will be assigned
- If you omit the `Space`, no space roles will be assigned

### `delete-user`

Delete a user

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `username`         | *Required* | All         | The user to delete
| `origin`           | *Optional* | 7, 8        | Origin for mapping a user account to a user in an external identity provider

```yaml
- put: cloud-foundry
  params:
    command: delete-user
    username: j.smith@example.com
```

### `create-user-provided-service`

Make a user-provided service instance available to CF apps

| Params              | Usage      | CLI Version | Description
| ---                 | ---        | ---         | ---
| `org`               | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`             | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance`  | *Required* | All         | The name to give the service instance
| `credentials`       | *Optional* | All         | Credentials, provided as YAML, inline json or in a file, to be exposed in the VCAP_SERVICES environment variable for bound applications
| `syslog_drain_url`  | *Optional* | All         | URL to which logs for bound applications will be streamed
| `route_service_url` | *Optional* | All         | URL to which requests for bound routes will be forwarded. Scheme for this URL must be https

```yaml
- put: cloud-foundry
  params:
    commands:
      # credentials as YAML
      - command: create-user-provided-service
        service_instance: my-db-mine
        credentials:
          username: admin
          password: pa55woRD
      # credentials as inline json
      - command: create-user-provided-service
        service_instance: my-db-mine
        credentials: '{"username":"admin","password":"pa55woRD"}'
      # credentials as json file
      - command: create-user-provided-service
        service_instance: another-db-mine
        credentials: path/to/credentials.json
      # syslog drain url
      - command: create-user-provided-service
        service_instance: my-drain-service
        syslog_drain_url: syslog://example.com
      # route service url
      - command: create-user-provided-service
        service_instance: my-route-service
        route_service_url: https://example.com
```

### `create-service`

Create a service instance

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service`          | *Required* | All         | The marketplace service name to create
| `plan`             | *Required* | All         | The service plan name to create
| `service_instance` | *Required* | All         | The name to give the service instance
| `broker`           | *Optional* | All         | Create a service instance from a particular broker. Required when service name is ambiguous
| `configuration`    | *Optional* | All         | Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
| `tags`             | *Optional* | All         | User provided tags
| `wait`             | *Optional* | All         | Wait for the operation to complete
| `timeout`          | *Optional* | 6, 7        | Max wait time for service creation, in seconds. Defaults to `600` (10 minutes) (*use with `wait` param*)
| `update_service`   | *Optional* | All         | Update service instance if it already exists. Defaults to `false`.

```yaml
- put: cloud-foundry
  params:
    command: create-service
    service: p-config-server
    plan: standard
    service_instance: my-config-server
    configuration: '{"count":1}'
    tags: "list, of, tags"
    wait: true
    update_service: true
```

### `update-service`

Update a service instance

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The name of the service instance
| `plan`             | *Required* | All         | Change service plan for a service instance
| `configuration`    | *Optional* | All         | Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
| `tags`             | *Optional* | All         | User provided tags
| `wait`             | *Optional* | All         | Wait for the operation to complete
| `timeout`          | *Optional* | 6, 7        | Max wait time for service update, in seconds. Defaults to `600` (10 minutes) (*use with `wait` param*)

```yaml
- put: cloud-foundry
  params:
    command: update-service
    service: p-config-server
    plan: pro
    service_instance: my-config-server
    configuration: '{"count":2}'
    tags: "list, of, tags"
    wait: true
```

### `delete-service`

Delete a service instance

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The service instance to delete
| `wait`             | *Optional* | All         | Wait for the operation to complete
| `timeout`          | *Optional* | 6, 7        | Max wait time for service update, in seconds. Defaults to `600` (10 minutes) (*use with `wait` param*)

```yaml
- put: cloud-foundry
  params:
    command: delete-service
    service_instance: my-config-server
    wait: true
```

### `share-service`

Share a service instance with another space

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The name of the service instance to share
| `other_org`        | *Optional* | All         | Org of the other space (Default: targeted org)
| `other_space`      | *Required* | All         | Space to share the service instance into

```yaml
- put: cloud-foundry
  params:
    command: share-service
    service_instance: my-shared-service
    other_org: other-org
    other_space: other-space
```

### `unshare-service`

Unshare a shared service instance from a space

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The name of the service instance to unshare
| `other_org`        | *Optional* | All         | Org of the other space (Default: targeted org)
| `other_space`      | *Required* | All         | Space to unshare the service instance from

```yaml
- put: cloud-foundry
  params:
    command: unshare-service
    service_instance: my-shared-service
    other_org: other-org
    other_space: other-space
```

### `create-service-key`

Create key for a service instance

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The name of the service instance for which the key is to be created
| `service_key`      | *Required* | All         | The name to give the service key
| `configuration`    | *Optional* | All         | Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: create-service-key
    service_instance: my-db
    service_key: my-db-service-key
```

### `delete-service-key`

Delete a service key

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The service instance that has the service key
| `service_key`      | *Required* | All         | The service key to delete
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: delete-service-key
    service_instance: my-db
    service_key: my-db-service-key
```

### `create-service-broker`

Create a service broker

Create or update a service broker. If a service broker already exists, updates the existing service broker.

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Optional* | All         | The organization to target (*required if `space_scoped: true`*)
| `space`            | *Optional* | All         | The space to target (*required if `space_scoped: true`*)
| `service_broker`   | *Required* | All         | The service broker name to create
| `username`         | *Required* | All         | The service broker username
| `password`         | *Required* | All         | The service broker password
| `url`              | *Required* | All         | The service broker url
| `space_scoped`     | *Optional* | All         | Make the broker's service plans only visible within the targeted space. Defaults to `false`.

```yaml
- put: cloud-foundry
  params:
    command: create-service-broker
    service_broker: some-service
    username: admin
    password: password
    url: http://broker.name.com
```

### `delete-service-broker`

Delete a service broker

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_broker`   | *Required* | All         | The service broker name to delete

```yaml
- put: cloud-foundry
  params:
    command: delete-service-broker
    service_broker: some-service
```

### `wait-for-service`

Wait for a service instance to start

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `service_instance` | *Required* | All         | The service instance to wait for
| `timeout`          | *Optional* | All         | Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)

```yaml
- put: cloud-foundry
  params:
    command: wait-for-service
    service_instance: my-config-server
    timeout: 300
```

### `enable-service-access`

Enable access to a service offering or service plan for one or all orgs

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `service`          | *Required* | All         | The marketplace service name to enable
| `broker`           | *Optional* | All         | Enable access to a service from a particular service broker. Required when service name is ambiguous
| `access_org`       | *Optional* | All         | Enable access for a specified organization
| `plan`             | *Optional* | All         | Enable access to a specified service plan

```yaml
- put: cloud-foundry
  params:
    command: enable-service-access
    service: some-service
    broker: some-service-broker
    access_org: myorg
    plan: simple
```

### `disable-service-access`

Disable access to a service offering or service plan for one or all orgs

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `service`          | *Required* | All         | The marketplace service name to disable
| `access_org`       | *Optional* | All         | Disable access for a specified organization
| `plan`             | *Optional* | All         | Disable access to a specified service plan

```yaml
- put: cloud-foundry
  params:
    command: disable-service-access
    service: some-service
    access_org: myorg
    plan: simple
```

###` bind-service`

Bind a service instance to an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The application to bind to the service
| `service_instance` | *Required* | All         | The service instance to bind to the application
| `configuration`    | *Optional* | All         | Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
| `binding_name`     | *Optional* | All         | Name to expose service instance to app process with
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: bind-service
    app_name: myapp
    service_instance: mydb
    configuration: '{"permissions":"read-only"}'
```

### `unbind-service`

Unbind a service instance from an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The application to unbind from the service instance
| `service_instance` | *Required* | All         | The service instance to unbind from the application
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: unbind-service
    app_name: myapp
    service_instance: mydb
```

### `bind-route-service`

Bind a service instance to an HTTP route

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | The domain to bind the route to
| `service_instance` | *Required* | All         | The service instance to bind the route to
| `hostname`         | *Optional* | All         | Hostname used in combination with `domain` to specify the route to bind
| `path`             | *Optional* | All         | Path used in combination with `hostname` and `domain` to specify the route to bind
| `configuration`    | *Optional* | All         | Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: bind-route-service
    domain: example.com
    service_instance: mylogger
    hostname: myhost
    path: foo
    configuration: '{"permissions":"read-only"}'
```

### `unbind-route-service`

Unbind a service instance from an HTTP route

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `domain`           | *Required* | All         | The domain to unbind the route from
| `service_instance` | *Required* | All         | The service instance to unbind the route from
| `hostname`         | *Optional* | All         | Hostname used in combination with `domain` to specify the route to unbind
| `path`             | *Optional* | All         | Path used in combination with `hostname` and `domain` to specify the route to unbind
| `wait`             | *Optional* | 8           | Wait for the operation to complete

```yaml
- put: cloud-foundry
  params:
    command: unbind-route-service
    domain: example.com
    service_instance: mylogger
    hostname: myhost
    path: foo
```

### `enable-feature-flag`

Allow use of a feature

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `feature_name`     | *Required* | All         | Feature to enable

```yaml
- put: cloud-foundry
  params:
    command: enable-feature-flag
    feature_name: service_instance_sharing
```

### `disable-feature-flag`

Prevent use of a feature

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `feature_name`     | *Required* | All         | Feature to disable

```yaml
- put: cloud-foundry
  params:
    command: disable-feature-flag
    feature_name: service_instance_sharing
```

### `push`

Push a new app or sync changes to an existing app

> A manifest can be used to specify values for required parameters. Any parameters specified will override manifest values.

| Params                  | Usage      | CLI Version | Description
| ---                     | ---        | ---         | ---
| `org`                   | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`                 | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`              | *Required* | All         | The name of the application (*Optional* if using a `manifest` that specifies the application name)
| `buildpack`             | *Optional* | All         | *Deprecated*, please use `buildpacks` instead.
| `buildpacks`            | *Optional* | All         | List of custom buildpacks by name (e.g. my-buildpack) or Git URL (e.g. 'https://github.com/cloudfoundry/java-buildpack.git') or Git URL with a branch or tag (e.g. 'https://github.com/cloudfoundry/java-buildpack.git#v3.3.0' for 'v3.3.0' tag). To use built-in buildpacks only, specify `default` or `"null"` (*note the use of double quotes!*)
| `disk_quota`            | *Optional* | All         | Disk limit (e.g. 256M, 1024M, 1G)
| `docker_image`          | *Optional* | All         | Docker-image to be used (e.g. user/docker-image-name)
| `docker_username`       | *Optional* | All         | This is used as the username to authenticate against a protected docker registry
| `docker_password`       | *Optional* | All         | This should be the users password when authenticating against a protected docker registry
| `domain`                | *Optional* | 6           | Domain to use instead of the default (e.g. apps.internal, subdomain.example.com)
| `environment_variables` | *Optional* | All         | Map of environment variables to pass to application
| `hostname`              | *Optional* | 6           | Hostname (e.g. my-subdomain)
| `instances`             | *Optional* | All         | Number of instances
| `manifest`              | *Optional* | All         | Path to manifest file, *or* valid application manifest yaml
| `memory`                | *Optional* | All         | Memory limit (e.g. 256M, 1024M, 1G)
| `no_start`              | *Optional* | All         | Do not start an app after pushing. Defaults to `false`.
| `path`                  | *Optional* | All         | Path to app directory or to a zip file of the contents of the app directory
| `stack`                 | *Optional* | All         | Stack to use (a stack is a pre-built file system, including an operating system, that can run apps)
| `startup_command`       | *Optional* | All         | Startup command, set to `"null"` (*note the use of double quotes!*) to reset to default start command
| `strategy`              | *Optional* | 7, 8        | Deployment strategy, either `rolling` or `null` (*note the absence of double quotes!*)
| `vars`                  | *Optional* | All         | Map of variables to pass to manifest
| `vars_files`            | *Optional* | All         | List of variables files to pass to manifest
| `show_app_log`          | *Optional* | All         | Outputs the app log after a failed startup, useful to debug issues when used together with the `app_name` option.
| `staging_timeout`       | *Optional* | All         | Max wait time for buildpack staging, in minutes
| `startup_timeout`       | *Optional* | All         | Max wait time for app instance startup, in minutes

```yaml
- put: cloud-foundry
  params:
    command: push
    app_name: myapp
    memory: 1G
    path: path/to/myapp-*.jar
    buildpacks:
      - java_buildpack
    manifest: path/to/manifest.yml
    vars:
      instances: 3
    vars_files:
      - path/to/vars.yml
    environment_variables:
      key: value
      key2: value2
```

Example directly specifying the manifest as yaml:
```yaml
- put: cloud-foundry
  params:
    command: push
    path: path/to/myapp-*.jar
    manifest:
      applications:
      - name: myapp
        memory: 1G
        buildpacks:
          - java_buildpack
        env:
          key: value
          key2: value2
```

### `zero-downtime-push`

Push a new app or sync changes to an existing app using a zero downtime strategy. A [manifest](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html) that describes the application must be specified.

> This command is designed to function as a replacement for the Concourse [cf-resource](https://github.com/cloudfoundry-community/cf-resource).

| Params                  | Usage      | CLI Version | Description
| ---                     | ---        | ---         | ---
| `org`                   | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`                 | *Required* | All         | The space to target (*Optional if set in the source config*)
| `manifest`              | *Required* | All         | Path to a application manifest file.
| `path`                  | *Optional* | All         | Path to the application to push. If this isn't set then it will be read from the manifest instead.
| `current_app_name`      | *Optional* | All         | This should be the name of the application that this will re-deploy over. If this is set the resource will perform a zero-downtime deploy.
| `environment_variables` | *Optional* | All         | Environment variable key/value pairs to add to the manifest.
| `vars`                  | *Optional* | All         | Map of variables to pass to manifest
| `vars_files`            | *Optional* | All         | List of variables files to pass to manifest
| `docker_image`          | *Optional* | All         | Docker-image to be used (e.g. user/docker-image-name)
| `docker_username`       | *Optional* | All         | This is used as the username to authenticate against a protected docker registry
| `docker_password`       | *Optional* | All         | This should be the users password when authenticating against a protected docker registry
| `show_app_log`          | *Optional* | All         | Outputs the app log after a failed startup, useful to debug issues when used together with the `current_app_name` option.
| `no_start`              | *Optional* | All         | Deploys the app but does not start it.
| `stack`                 | *Optional* | All         | Stack to use (a stack is a pre-built file system, including an operating system, that can run apps)
| `staging_timeout`       | *Optional* | All         | Max wait time for buildpack staging, in minutes
| `startup_timeout`       | *Optional* | All         | Max wait time for app instance startup, in minutes

```yaml
- put: cloud-foundry
  params:
    command: zero-downtime-push
    manifest: path/to/manifest.yml
    path: path/to/myapp-*.jar
    current_app_name: myapp
    environment_variables:
      key: value
      key2: value2
    vars:
      instances: 3
    vars_files:
      - path/to/vars.yml
```

### `set-env`

Set an env variable for an app

| Params                  | Usage      | CLI Version | Description
| ---                     | ---        | ---         | ---
| `org`                   | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`                 | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`              | *Required* | All         | The name of the application
| `environment_variables` | *Required* | All         | Environment variable key/value pairs to set.

```yaml
- put: cloud-foundry
  params:
    command: set-env
    app_name: myapp
    environment_variables:
      JBP_CONFIG_OPEN_JDK_JRE: "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }"
      SOME_OTHER_KEY: SOME_OTHER_VALUE
```

### `start`

Start an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application
| `staging_timeout`  | *Optional* | All         | Max wait time for buildpack staging, in minutes
| `startup_timeout`  | *Optional* | All         | Max wait time for app instance startup, in minutes

```yaml
- put: cloud-foundry
  params:
    command: start
    app_name: myapp
```

### `stop`

Stop an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application

```yaml
- put: cloud-foundry
  params:
    command: stop
    app_name: myapp
```

### `restart`

Stop all instances of the app, then start them again.

> This command will cause downtime unless you use `strategy: rolling`.

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Optional* | All         | The organization to target (required if not set in the source config)
| `space`            | *Optional* | All         | The space to target (required if not set in the source config)
| `app_name`         | *Required* | All         | The name of the application
| `strategy`         | *Optional* | 7, 8        | Deployment strategy, either `rolling` or `null`.
| `no_wait`          | *Optional* | 7, 8        | Exit when the first instance of the web process is healthy
| `staging_timeout`  | *Optional* | All         | Max wait time for buildpack staging, in minutes
| `startup_timeout`  | *Optional* | All         | Max wait time for app instance startup, in minutes

```yaml
- put: cloud-foundry
  params:
    command: restart
    app_name: myapp
```

### `restage`

Stage the app's latest package into a droplet and restart the app with this new droplet and updated configuration (environment variables, service bindings, buildpack, stack, etc.).

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application
| `strategy`         | *Optional* | 7, 8        | Deployment strategy, either `rolling` or `null`
| `no_wait`          | *Optional* | 7, 8        | Exit when the first instance of the web process is healthy
| `staging_timeout`  | *Optional* | All         | Max wait time for buildpack staging, in minutes
| `startup_timeout`  | *Optional* | All         | Max wait time for app instance startup, in minutes

```yaml
- put: cloud-foundry
  params:
    command: restage
    app_name: myapp
```

### `delete`

Delete an app

| Params                 | Usage      | CLI Version | Description
| ---                    | ---        | ---         | ---
| `org`                  | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`                | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`             | *Required* | All         | The name of the application
| `delete_mapped_routes` | *Optional* | All         | Delete any mapped routes. Defaults to `false`.

```yaml
- put: cloud-foundry
  params:
    command: delete
    app_name: myapp
    delete_mapped_routes: true
```

### `rename`

Rename an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application
| `new_app_name`     | *Required* | All         | The new name of the application

```yaml
- put: cloud-foundry
  params:
    command: rename
    app_name: myapp
    new_app_name: myapp-new
```

### `add-network-policy`

Create policy to allow direct network traffic from one app to another

| Params              | Usage      | CLI Version | Description
| ---                 | ---        | ---         | ---
| `org`               | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`             | *Required* | All         | The space to target (*Optional if set in the source config*)
| `source_app`        | *Required* | All         | The name of the source application
| `destination_app`   | *Required* | All         | Name of app to connect to
| `port`              | *Optional* | All         | Port or range of ports for connection to destination app (Default: `8080`)
| `protocol`          | *Optional* | All         | Protocol to connect apps with (Default: `tcp`)
| `destination_org`   | *Optional* | All         | The org of the destination app (Default: targeted `org`)
| `destination_space` | *Optional* | All         | The space of the destination app (Default: targeted `space`)

```yaml
- put: cloud-foundry
  params:
    command: add-network-policy
    source_app: frontend
    destination_app: backend
    protocol: tcp
    port: 8080
```

### `remove-network-policy`

Remove network traffic policy of an app

| Params              | Usage      | CLI Version | Description
| ---                 | ---        | ---         | ---
| `org`               | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`             | *Required* | All         | The space to target (*Optional if set in the source config*)
| `source_app`        | *Required* | All         | The name of the source application
| `destination_app`   | *Required* | All         | Name of app to connect to
| `port`              | *Required* | All         | Port or range of ports that destination app is connected with
| `protocol`          | *Required* | All         | Protocol that apps are connected with
| `destination_org`   | *Optional* | All         | The org of the destination app (Default: targeted `org`)
| `destination_space` | *Optional* | All         | The space of the destination app (Default: targeted `space`)

```yaml
- put: cloud-foundry
  params:
    command: remove-network-policy
    source_app: frontend
    destination_app: backend
    protocol: tcp
    port: 8080
```

### `create-buildpack`

Create a buildpack

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `buildpack`        | *Required* | All         | The name of the buildpack
| `path`             | *Required* | All         | Path to buildpack zip file, url to a zip file, or a local directory
| `position`         | *Required* | All         | The order in which the buildpacks are checked during buildpack auto-detection
| `enabled`          | *Optional* | All         | Set to `false` to disable the buildpack from being used for staging

```yaml
- put: cloud-foundry
  params:
    command: create-buildpack
    buildpack: java_buildpack_offline
    path: https://github.com/cloudfoundry/java-buildpack/releases/download/v4.48.3/java-buildpack-v4.48.3.zip
    position: 99
```

### `update-buildpack`

Update a buildpack

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `buildpack`        | *Required* | All         | The name of the buildpack
| `path`             | *Optional* | All         | Path to buildpack zip file, url to a zip file, or a local directory
| `assign_stack`     | *Optional* | All         | Assign a stack to a buildpack that does not have a stack association
| `position`         | *Optional* | All         | The order in which the buildpacks are checked during buildpack auto-detection
| `enabled`          | *Optional* | All         | Set to `false` to disable the buildpack from being used for staging
| `locked`           | *Optional* | All         | Set to `true` to lock the buildpack to prevent updates

```yaml
- put: cloud-foundry
  params:
    command: update-buildpack
    buildpack: java_buildpack_offline
    assign_stack: cflinuxfs3
```

### `delete-buildpack`

Delete a buildpack

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `buildpack`        | *Required* | All         | The name of the buildpack
| `stack`            | *Optional* | All         | Specify stack to disambiguate buildpacks with the same name. Required when buildpack name is ambiguous

```yaml
- put: cloud-foundry
  params:
    command: delete-buildpack
    buildpack: java_buildpack_offline
    stack: cflinuxfs3
```

### `run-task`

Run a one-off task on an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application
| `task_command`     | *Required* | All         | The command to run for the task
| `task_name`        | *Optional* | All         | Name to give the task (generated if omitted)
| `memory`           | *Optional* | All         | Memory limit (e.g. 256M, 1024M, 1G)
| `disk_quota`       | *Optional* | All         | Disk limit (e.g. 256M, 1024M, 1G)

```yaml
- put: cloud-foundry
  params:
    command: run-task
    app_name: myapp
    task_command: bundle exec rake db:migrate
    task_name: migrate
    memory: 256M
    disk_quota: 1G
```

### `scale`

Change or view the instance count, disk space limit, and memory limit for an app

| Params             | Usage      | CLI Version | Description
| ---                | ---        | ---         | ---
| `org`              | *Required* | All         | The organization to target (*Optional if set in the source config*)
| `space`            | *Required* | All         | The space to target (*Optional if set in the source config*)
| `app_name`         | *Required* | All         | The name of the application
| `instances`        | *Optional* | All         | Number of instances
| `disk_quota`       | *Optional* | All         | Disk limit (e.g. 256M, 1024M, 1G)
| `memory`           | *Optional* | All         | Memory limit (e.g. 256M, 1024M, 1G)

```yaml
- put: cloud-foundry
  params:
    command: scale
    app_name: myapp
    instances: 3
    disk_quota: 1G
    memory: 2G
```
#### allow-space-ssh

Allow space ssh in the targeted space
- `space`: _Optional._ The targeted space (required if not set in the source config)

```yml
- put: cf-allow-space-ssh
  resource: cf-env
  params:
    command: allow-space-ssh
    space: myspace
```

#### disallow-space-ssh

Disallow space ssh in the targeted space
- `space`: _Optional._ The targeted space (required if not set in the source config)

```yml
- put: cf-disallow-space-ssh
  resource: cf-env
  params:
    command: disallow-space-ssh
    space: myspace
```