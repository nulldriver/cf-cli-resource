# cf cli Concourse Resource

|            | status |
| ---------- | ------ |
| build      | [![build](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/build/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/build/builds/latest) |
| v6 tests   | [![v6 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v6/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v6/builds/latest) |
| v7 tests   | [![v7 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v7/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v7/builds/latest) |
| v8 tests   | [![v8 tests](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v8/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/test-cf-cli-v8/builds/latest) |
| image scan | [![image scan](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/cf-cli-resource/jobs/scan-image/badge)](https://ci.nulldriver.com/teams/resources/pipelines/cf-cli-resource/jobs/scan-image/builds/latest) |
| docker     | [![Docker Pulls](https://img.shields.io/docker/pulls/nulldriver/cf-cli-resource.svg)](https://hub.docker.com/r/nulldriver/cf-cli-resource/) |

An output only resource capable of running lots of Cloud Foundry cli commands.

## Source Configuration

Note: you must provide either `username` and `password` or `client_id` and `client_secret`.

- `api`: _Required._ The address of the Cloud Controller in the Cloud Foundry deployment.
- `username`: _Optional._ The username used to authenticate.
- `password`: _Optional._ The password used to authenticate.
- `origin`: _Optional._ The identity provider to be used for authentication (only valid for `username` & `password` authentication)
- `client_id`: _Optional._ The client id used to authenticate.
- `client_secret`: _Optional._ The client secret used to authenticate.
- `skip_cert_check`: _Optional._ Check the validity of the CF SSL cert. Defaults to `false`.
- `org`: _Optional._ Sets the default organization to target (can be overridden in the params config).
- `space`: _Optional._ Sets the default space to target (can be overridden in the params config).
- `cf_color`: _Optional._ Set to `false` to not colorize cf output (can be overridden in the params config).
- `cf_dial_timeout`: _Optional._ Max wait time to establish a connection, including name resolution, in seconds (can be overridden in the params config).
- `cf_trace`: _Optional._ Set to `true` to print cf API request diagnostics to stdout (can be overridden in the params config).

```yml
resource_types:
  - name: cf-cli-resource
    type: registry-image
    source:
      repository: nulldriver/cf-cli-resource
      tag: latest

resources:
  - name: cf-env
    type: cf-cli-resource
    source:
      api: https://api.local.pcfdev.io
      username: admin
      password: admin
      skip_cert_check: true
```

## Multiple Command Syntax

This resource is capable of running single commands in separate `put` steps.

_NOTE_: A common practice is to use different logical names for each `put` step and reuse the same `resource`.
In this example were we use `cf-create-org` and `cf-create-space` to describe the `put` steps and use the same `cf-env` resource for both steps.

```yml
- put: cf-create-org
  resource: cf-env
  params:
    command: create-org
    org: myorg
- put: cf-create-space
  resource: cf-env
  params:
    command: create-space
    org: myorg
    space: myspace
```

_or_ they can be combined in a single `put` step:

```yml
- put: cf-create-org-and-space
  resource: cf-env
  params:
    commands:
      - command: create-org
        org: myorg
      - command: create-space
        org: myorg
        space: myspace
```

And, of course, if you have your `org` and `space` defined in the `source` config,
it gets even simpler:

```yml
- put: cf-create-org-and-space
  resource: cf-env
  params:
    commands:
      - command: create-org
      - command: create-space
```

## CF_HOME

The standard way to authenticate the `cf-cli-resource` with a target Cloud Foundry environment is to either use `username` and `password` or `client_id` and `client_secret`, which will save a `$CF_HOME/.cf/config.json` file containing the API endpoint, and access token. For some pipeline workflows, it is necessary to authenticate using alternative methods and then supply the pre-configured `config.json` to the `cf-cli-resource`.

> See [examples/cf_home-auth/pipeline.yml](examples/cf_home-auth/pipeline.yml) for a full example

For example:

```yaml
resources:
  - name: cf-prod
    type: cf-cli-resource

jobs:
  - name: deploy
    plan:
      - get: my-repo
      - task: authenticate
        file: my-repo/some-script-that-authenticates-and-creates-a-cf-config-json.yml
      - put: cf-prod
        params:
          cf_home: authenticate-task-output
          commands:
            - command: push
              path: my-repo/myapp
              manifest: my-repo/manifest.yml
```

## Command via file input

This resource supports file inputs. This allows the pipeline to parameterize and generate commands during pipeline execution.

- `command_file`: _Optional._ Contains path to a YAML file that contains the same fields as `params`; including `command` or `commands`. If used, this resource uses only the configuration listed in this file. All other configurations specified in the `params` section will be ignored. The `command_file` field (if exists) is ignored within the content of the file itself.

```yml
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
          app_name: app
          delete_mapped_routes: true
          EOF
    outputs:
      - name: cf_command
- put: cf-delete
  resource: cf-env
  params:
    command: delete
    command_file: cf_command/params.yml
```

## Behavior

### `out`: Run a cf cli command.

Run cf command(s) on a Cloud Foundry installation.

#### create-org

Create an org

- `org`: _Optional._ The organization to create (required if not set in the source config)

```yml
- put: cf-create-org
  resource: cf-env
  params:
    command: create-org
    org: myorg
```

#### delete-org

Delete an org

- `org`: _Optional._ The organization to delete (required if not set in the source config)

```yml
- put: cf-delete-org
  resource: cf-env
  params:
    command: delete-org
    org: myorg
```

#### create-space

Create a space

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to create (required if not set in the source config)

```yml
- put: cf-create-space
  resource: cf-env
  params:
    command: create-space
    org: myorg
    space: myspace
```

#### delete-space

Delete a space

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to delete (required if not set in the source config)

```yml
- put: cf-delete-space
  resource: cf-env
  params:
    command: delete-space
    org: myorg
    space: myspace
```

#### create-domain

Create a domain in an org for later use

- `org`: _Optional._ The organization to create the domain in (required if not set in the source config)
- `domain`: _Optional._ The domain to add to the organization

```yml
- put: cf-create-domain
  resource: cf-env
  params:
    command: create-domain
    org: myorg
    domain: example.com
```

#### delete-domain

Delete a domain

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `domain`: _Optional._ The domain to delete

```yml
- put: cf-delete-domain
  resource: cf-env
  params:
    command: delete-domain
    domain: example.com
```

#### create-route

Create a url route in a space for later use

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `other_space`: _Optional._ The space for the route (if not set the source or params specified `space` will be used)
- `domain`: _Required._ Domain for the HTTP route
- `hostname`: _Optional._ Hostname for the HTTP route (required for shared domains)
- `path`: _Optional._ Path for the HTTP route

```yml
- put: cf-create-route
  resource: cf-env
  params:
    command: create-route
    domain: example.com
    hostname: myhost
    path: foo
```

#### map-route

Add a url route to an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The application to map the route to
- `domain`: _Required._ The domain to map to the application
- `hostname`: _Optional._ Hostname for the HTTP route (required for shared domains)
- `path`: _Optional._ Path for the HTTP route

```yml
- put: cf-map-route
  resource: cf-env
  params:
    command: map-route
    app_name: myapp-ui
    domain: example.com
    hostname: myhost
    path: foo
```

#### unmap-route

Remove a url route from an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The application to map the route to
- `domain`: _Required._ The domain to unmap from the application
- `hostname`: _Optional._ Hostname used to identify the HTTP route
- `path`: _Optional._ Path used to identify the HTTP route

```yml
- put: cf-unmap-route
  resource: cf-env
  params:
    command: unmap-route
    app_name: myapp-ui
    domain: example.com
    hostname: myhost
    path: foo
```

#### delete-route

Delete a route

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `domain`: _Required._ Domain used to identify the HTTP route
- `hostname`: _Optional._ Hostname used to identify the HTTP route
- `path`: _Optional._ Path used to identify the HTTP route

```yml
- put: cf-delete-route
  resource: cf-env
  params:
    command: delete-route
    domain: example.com
    hostname: myhost
    path: foo
```

#### create-user

Create a new user

- `username`: _Required._ The user to create
- `password`: _Optional._ The password (must specify either `password` or `origin`)
- `origin`: _Optional._ The authentication origin (e.g. ldap, provider-alias) (must specify either `password` or `origin`)

Create a user with credentials:

```yml
- put: prepare-env
  resource: cf-env
  params:
    command: create-user
    username: j.smith@example.com
    password: S3cr3t
```

Create an LDAP user:

```yml
- put: prepare-env
  resource: cf-env
  params:
    command: create-user
    username: j.smith@example.com
    origin: ldap
```

#### create-users-from-file

Bulk create users from a csv file

- `file`: _Required._ The csv file containing the users

```yml
- put: prepare-env
  resource: cf-env
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
- If you omit the Org, no org or space roles will be assigned
- If you omit the Space, no space roles will be assigned

#### delete-user

Delete a user

- `username`: _Required._ The user to delete

```yml
- put: prepare-env
  resource: cf-env
  params:
    command: delete-user
    username: j.smith@example.com
```

#### create-user-provided-service

Make a user-provided service instance available to CF apps

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The name to give the service instance
- Options: _Only specify one._
  - `credentials`: Credentials, provided as YAML, inline json or in a file, to be exposed in the VCAP_SERVICES environment variable for bound applications
  - `syslog_drain_url`: URL to which logs for bound applications will be streamed
  - `route_service_url`: URL to which requests for bound routes will be forwarded. Scheme for this URL must be https

```yml
- put: cf-create-user-provided-service
  resource: cf-env
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

#### create-service

Create a service instance

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service`: _Required._ The marketplace service name to create
- `plan`: _Required._ The service plan name to create
- `service_instance`: _Required._ The name to give the service instance
- `broker`: _Optional._ Create a service instance from a particular broker. Required when service name is ambiguous
- `configuration`: _Optional._ Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
- `tags`: _Optional._ User provided tags
- `timeout`: _Optional._ Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)
- `wait`: _Optional._ Wait for the operation to complete
- `update_service`: _Optional._ Update service instance if it already exists. Defaults to `false`.

```yml
- put: cf-create-service
  resource: cf-env
  params:
    command: create-service
    service: p-config-server
    plan: standard
    service_instance: my-config-server
    configuration: '{"count":1}'
    tags: "list, of, tags"
    timeout: 300
    wait: true
```

#### update-service

Update a service instance

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The name of the service instance
- `plan`: _Required._ Change service plan for a service instance
- `configuration`: _Optional._ Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
- `tags`: _Optional._ User provided tags
- `timeout`: _Optional._ Max wait time for service update, in seconds. Defaults to `600` (10 minutes)
- `wait`: _Optional._ Wait for the operation to complete


```yml
- put: cf-update-service
  resource: cf-env
  params:
    command: update-service
    service: p-config-server
    plan: pro
    service_instance: my-config-server
    configuration: '{"count":2}'
    tags: "list, of, tags"
    timeout: 300
    wait: true
```

#### delete-service

Delete a service instance

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The service instance to delete
- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-delete-service
  resource: cf-env
  params:
    command: delete-service
    service_instance: my-config-server
    wait: true
```

#### share-service

Share a service instance with another space

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The name of the service instance to share
- `other_org`: _Optional._ Org of the other space (Default: targeted org)
- `other_space`: _Required._ Space to share the service instance into

```yml
- put: cf-share-service
  resource: cf-env
  params:
    command: share-service
    service_instance: my-shared-service
    other_org: other-org
    other_space: other-space
```

#### unshare-service

Unshare a shared service instance from a space

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The name of the service instance to unshare
- `other_org`: _Optional._ Org of the other space (Default: targeted org)
- `other_space`: _Required._ Space to unshare the service instance from

```yml
- put: cf-unshare-service
  resource: cf-env
  params:
    command: unshare-service
    service_instance: my-shared-service
    other_org: other-org
    other_space: other-space
```

#### create-service-key

Create a service key

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The name of the service instance for which the key is to be created
- `service_key`: _Required._ The name to give the service key
- `configuration`: _Optional._ Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-create-service-key
  resource: cf-env
  params:
    command: create-service-key
    service_instance: my-db
    service_key: my-db-service-key
```

#### delete-service-key

Delete a service key

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The service instance that has the service key
- `service_key`: _Required._ The service key to delete

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-delete-service-key
  resource: cf-env
  params:
    command: delete-service-key
    service_instance: my-db
    service_key: my-db-service-key
```

#### create-service-broker

Create/Update a service broker. If a service broker already exists, updates the existing service broker.

- `org`: _Optional._ The organization to target (required if `space_scoped: true`)
- `space`: _Optional._ The space to target (required if `space_scoped: true`)
- `service_broker`: _Required._ The service broker name to create
- `username`: _Required._ The service broker username
- `password`: _Required._ The service broker password
- `url`: _Required._ The service broker url
- `space_scoped`: _Optional._ Make the broker's service plans only visible within the targeted space. Defaults to `false`.

```yml
- put: cf-create-service-broker
  resource: cf-env
  params:
    command: create-service-broker
    service_broker: some-service
    username: admin
    password: password
    url: http://broker.name.com
    space_scoped: true
```

#### delete-service-broker

Deletes a service broker

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_broker`: _Required._ The service broker name to delete

```yml
- put: cf-delete-service-broker
  resource: cf-env
  params:
    command: delete-service-broker
    service_broker: some-service
```

#### wait-for-service

Wait for a service instance to start

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `service_instance`: _Required._ The service instance to wait for
- `timeout`: _Optional._ Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)

```yml
- put: cf-wait-for-service
  resource: cf-env
  params:
    command: wait-for-service
    service_instance: my-config-server
    timeout: 300
```

#### enable-service-access

Enable access to a service or service plan for one or all orgs

- `service`: _Required._ The marketplace service name to enable
- `broker`: _Optional._ Enable access to a service from a particular service broker. Required when service name is ambiguous
- `access_org`: _Optional._ Enable access for a specified organization
- `plan`: _Optional._ Enable access to a specified service plan

```yml
- put: cf-enable-service-access
  resource: cf-env
  params:
    command: enable-service-access
    service: some-service
    broker: some-service-broker
    access_org: myorg
    plan: simple
```

#### disable-service-access

Disable access to a service or service plan for one or all orgs

- `service`: _Required._ The marketplace service name to disable
- `access_org`: _Optional._ Disable access for a specified organization
- `plan`: _Optional._ Disable access to a specified service plan

```yml
- put: cf-disable-service-access
  resource: cf-env
  params:
    command: disable-service-access
    service: some-service
    access_org: myorg
    plan: simple
```

#### bind-service

Bind a service instance to an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The application to bind to the service
- `service_instance`: _Required._ The service instance to bind to the application
- `configuration`: _Optional._ Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
- `binding_name`: _Optional._ Name to expose service instance to app process with

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-bind-service
  resource: cf-env
  params:
    command: bind-service
    app_name: myapp-ui
    service_instance: mydb
    configuration: '{"permissions":"read-only"}'
```

#### unbind-service

Unbind a service instance from an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The application to unbind from the service instance
- `service_instance`: _Required._ The service instance to unbind from the application

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-unbind-service
  resource: cf-env
  params:
    command: unbind-service
    app_name: myapp-ui
    service_instance: mydb
```

#### bind-route-service

Bind a service instance to an HTTP route

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `domain`: _Required._ The domain to bind the route to
- `service_instance`: _Required._ The service instance to bind the route to
- `hostname`: _Optional._ Hostname used in combination with `domain` to specify the route to bind
- `path`: _Optional._ Path used in combination with `hostname` and `domain` to specify the route to bind
- `configuration`: _Optional._ Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-bind-route-service
  resource: cf-env
  params:
    command: bind-route-service
    domain: example.com
    service_instance: mylogger
    hostname: myhost
    path: foo
    configuration: '{"permissions":"read-only"}'
```

#### unbind-route-service

Unbind a service instance from an HTTP route

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `domain`: _Required._ The domain to unbind the route from
- `service_instance`: _Required._ The service instance to unbind the route from
- `hostname`: _Optional._ Hostname used in combination with DOMAIN to specify the route to unbind
- `path`: _Optional._ Path used in combination with HOSTNAME and DOMAIN to specify the route to unbind

##### cf cli `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 8` in the resource `source` params.

- `wait`: _Optional._ Wait for the operation to complete

```yml
- put: cf-unbind-route-service
  resource: cf-env
  params:
    command: unbind-route-service
    domain: example.com
    service_instance: mylogger
    hostname: myhost
    path: foo
```

#### enable-feature-flag

Allow use of a feature

- `feature_name`: _Required._ Feature to enable

```yml
- put: cf-enable-feature-flag
  resource: cf-env
  params:
    command: enable-feature-flag
    feature_name: service_instance_sharing
```

#### disable-feature-flag

Prevent use of a feature

- `feature_name`: _Required._ Feature to disable

```yml
- put: cf-disable-feature-flag
  resource: cf-env
  params:
    command: disable-feature-flag
    feature_name: service_instance_sharing
```

#### push

Push a new app or sync changes to an existing app

_NOTE_: A manifest can be used to specify values for required parameters. Any parameters specified will override manifest values.

##### Common params

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application (_Optional_ if using a `manifest` that specifies the application name)
- `buildpack`: _Optional._ _Deprecated_, please use `buildpacks` instead.
- `buildpacks`: _Optional._ List of custom buildpacks by name (e.g. my-buildpack) or Git URL (e.g. 'https://github.com/cloudfoundry/java-buildpack.git') or Git URL with a branch or tag (e.g. 'https://github.com/cloudfoundry/java-buildpack.git#v3.3.0' for 'v3.3.0' tag). To use built-in buildpacks only, specify `default` or `"null"` (note the use of double quotes!)
- `disk_quota`: _Optional._ Disk limit (e.g. 256M, 1024M, 1G)
- `docker_image`: _Optional._ Docker-image to be used (e.g. user/docker-image-name)
- `docker_username`: _Optional._ This is used as the username to authenticate against a protected docker registry
- `docker_password`: _Optional._ This should be the users password when authenticating against a protected docker registry
- `environment_variables`: _Optional._ Map of environment variables to pass to application
- `instances`: _Optional._ Number of instances
- `manifest`: _Optional._ Path to manifest file, _or_ valid application manifest yaml
- `memory`: _Optional._ Memory limit (e.g. 256M, 1024M, 1G)
- `no_start`: _Optional._ Do not start an app after pushing. Defaults to `false`.
- `path`: _Optional._ Path to app directory or to a zip file of the contents of the app directory
- `stack`: _Optional._ Stack to use (a stack is a pre-built file system, including an operating system, that can run apps)
- `startup_command`: _Optional._ Startup command, set to `"null"` (note the use of double quotes!) to reset to default start command
- `vars`: _Optional._ Map of variables to pass to manifest
- `vars_files`: _Optional._ List of variables files to pass to manifest
- `show_app_log`: _Optional._ Outputs the app log after a failed startup, useful to debug issues when used together with the `app_name` option.
- `staging_timeout`: _Optional._ Max wait time for buildpack staging, in minutes
- `startup_timeout`: _Optional._ Max wait time for app instance startup, in minutes

##### cf cli `v6` specific params

- `domain`: _Optional._ Domain to use instead of the default (e.g. apps.internal, subdomain.example.com)
- `hostname`: _Optional._ Hostname (e.g. my-subdomain)

##### cf cli `v7` and `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 7` or `cf_cli_version: 8` in the resource `source` params.

- `strategy`: _Optional._ Deployment strategy, either rolling or `"null"` (note the use of double quotes!).

```yml
- put: cf-push
  resource: cf-env
  params:
    command: push
    app_name: myapp-ui
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
```yml
- put: cf-push
  resource: cf-env
  params:
    command: push
    path: path/to/myapp-*.jar
    manifest:
      applications:
      - name: myapp-ui
        memory: 1G
        buildpacks:
          - java_buildpack
        env:
          key: value
          key2: value2
```

#### zero-downtime-push

Deploy an application to a Cloud Foundry

Pushes an application to the Cloud Foundry detailed in the source configuration. A [manifest](https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html) that describes the application must be specified.

_NOTE_: This command is designed to function as a replacement for the Concourse [cf-resource](https://github.com/cloudfoundry-community/cf-resource).

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `manifest`: _Required._ Path to a application manifest file.
- `path`: _Optional._ Path to the application to push. If this isn't set then it will be read from the manifest instead.
- `current_app_name`: _Optional._ This should be the name of the application that this will re-deploy over. If this is set the resource will perform a zero-downtime deploy.
- `environment_variables`: _Optional._ Environment variable key/value pairs to add to the manifest.
- `vars`: _Optional._ Map of variables to pass to manifest
- `vars_files`: _Optional._ List of variables files to pass to manifest
- `docker_image`: _Optional._ Docker-image to be used (e.g. user/docker-image-name)
- `docker_username`: _Optional._ This is used as the username to authenticate against a protected docker registry
- `docker_password`: _Optional._ This should be the users password when authenticating against a protected docker registry
- `show_app_log`: _Optional._ Outputs the app log after a failed startup, useful to debug issues when used together with the `current_app_name` option.
- `no_start`: _Optional._ Deploys the app but does not start it.
- `stack`: _Optional._ Stack to use (a stack is a pre-built file system, including an operating system, that can run apps)
- `staging_timeout`: _Optional._ Max wait time for buildpack staging, in minutes
- `startup_timeout`: _Optional._ Max wait time for app instance startup, in minutes

```yml
- put: cf-zero-downtime-push
  resource: cf-env
  params:
    command: zero-downtime-push
    manifest: path/to/manifest.yml
    path: path/to/myapp-*.jar
    current_app_name: myapp-ui
    environment_variables:
      key: value
      key2: value2
    vars:
      instances: 3
    vars_files:
      - path/to/vars.yml
```

#### set-env

Set an env variable for an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `environment_variables`: _Required._ Environment variable key/value pairs to set.

```yml
- put: cf-set-env
  resource: cf-env
  params:
    command: set-env
    app_name: myapp-ui
    environment_variables:
      JBP_CONFIG_OPEN_JDK_JRE: "{ jre: { version: 11.+ }, memory_calculator: { stack_threads: 25 } }"
      SOME_OTHER_KEY: SOME_OTHER_VALUE
```

#### start

Start an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `staging_timeout`: _Optional._ Max wait time for buildpack staging, in minutes
- `startup_timeout`: _Optional._ Max wait time for app instance startup, in minutes

```yml
- put: cf-start
  resource: cf-env
  params:
    command: start
    app_name: myapp-ui
    staging_timeout: 15
    startup_timeout: 5
```

#### stop

Stop an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application

```yml
- put: cf-stop
  resource: cf-env
  params:
    command: stop
    app_name: myapp-ui
```

#### restart

Stop all instances of the app, then start them again. This causes downtime.

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `staging_timeout`: _Optional._ Max wait time for buildpack staging, in minutes
- `startup_timeout`: _Optional._ Max wait time for app instance startup, in minutes

```yml
- put: cf-restart
  resource: cf-env
  params:
    command: restart
    app_name: myapp-ui
    staging_timeout: 15
    startup_timeout: 5
```

#### restage

Recreate the app's executable artifact using the latest pushed app files and the latest environment (variables, service bindings, buildpack, stack, etc.)

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `staging_timeout`: _Optional._ Max wait time for buildpack staging, in minutes
- `startup_timeout`: _Optional._ Max wait time for app instance startup, in minutes

##### cf cli `v7` and `v8` specific params

_NOTE_: Enable these by specifying `cf_cli_version: 7` or `cf_cli_version: 8` in the resource `source` params.

- `strategy`: _Optional._ Deployment strategy, either rolling or null
- `no_wait`: _Optional._ Exit when the first instance of the web process is healthy

```yml
- put: cf-restage
  resource: cf-env
  params:
    command: restage
    app_name: myapp-ui
    staging_timeout: 15
    startup_timeout: 5
```

#### delete

Delete an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `delete_mapped_routes`: _Optional._ Delete any mapped routes. Defaults to `false`.

```yml
- put: cf-delete
  resource: cf-env
  params:
    command: delete
    app_name: myapp-ui
    delete_mapped_routes: true
```

#### rename

Rename an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `new_app_name`: _Required._ The new name of the application

```yml
- put: cf-rename
  resource: cf-env
  params:
    command: rename
    app_name: myapp-ui
    new_app_name: my-new-app-ui
```

#### add-network-policy

Create policy to allow direct network traffic from one app to another

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `source_app`: _Required._ The name of the source application
- `destination_app`: _Required._ Name of app to connect to
- `port`: _Optional._ Port or range of ports for connection to destination app (Default: 8080)
- `protocol`: _Optional._ Protocol to connect apps with (Default: tcp)
- `destination_org`: _Optional._ The org of the destination app (Default: targeted org)
- `destination_space`: _Optional._ The space of the destination app (Default: targeted space)

```yml
- put: cf-add-network-policy
  resource: cf-env
  params:
    command: add-network-policy
    source_app: frontend
    destination_app: backend
    protocol: tcp
    port: 8080
```

#### remove-network-policy

Remove network traffic policy of an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `source_app`: _Required._ The name of the source application
- `destination_app`: _Required._ Name of app to connect to
- `port`: _Required._ Port or range of ports that destination app is connected with
- `protocol`: _Required._ Protocol that apps are connected with
- `destination_org`: _Optional._ The org of the destination app (Default: targeted org)
- `destination_space`: _Optional._ The space of the destination app (Default: targeted space)

```yml
- put: cf-remove-network-policy
  resource: cf-env
  params:
    command: remove-network-policy
    source_app: frontend
    destination_app: backend
    protocol: tcp
    port: 8080
```

#### create-buildpack

Create a buildpack

- `buildpack`: _Required._ The name of the buildpack
- `path`: _Required._ Path to buildpack zip file, url to a zip file, or a local directory
- `position`: _Required._ The order in which the buildpacks are checked during buildpack auto-detection
- `enabled`: _Optional._ Set to `false` to disable the buildpack from being used for staging

```yml
- put: cf-create-buildpack
  resource: cf-env
  params:
    command: create-buildpack
    buildpack: java_buildpack_offline
    path: https://github.com/cloudfoundry/java-buildpack/releases/download/v4.19.1/java-buildpack-v4.19.1.zip
    position: 99
```

#### update-buildpack

Update a buildpack

- `buildpack`: _Required._ The name of the buildpack
- `path`: _Optional._ Path to buildpack zip file, url to a zip file, or a local directory
- `assign_stack`: _Optional._ Assign a stack to a buildpack that does not have a stack association
- `position`: _Optional._ The order in which the buildpacks are checked during buildpack auto-detection
- `enabled`: _Optional._ Set to `false` to disable the buildpack from being used for staging
- `locked`: _Optional._ Set to `true` to lock the buildpack to prevent updates

```yml
- put: cf-update-buildpack
  resource: cf-env
  params:
    command: update-buildpack
    buildpack: java_buildpack_offline
    assign_stack: cflinuxfs3
```

#### delete-buildpack

Delete a buildpack

- `buildpack`: _Required._ The name of the buildpack
- `stack`: _Optional._ Specify stack to disambiguate buildpacks with the same name. Required when buildpack name is ambiguous

```yml
- put: cf-delete-buildpack
  resource: cf-env
  params:
    command: delete-buildpack
    buildpack: java_buildpack_offline
    stack: cflinuxfs3
```

#### run-task

Run a one-off task on an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `task_command`: _Required._ The command to run for the task
- `task_name`: _Optional._ Name to give the task (generated if omitted)
- `memory`: _Optional._ Memory limit (e.g. 256M, 1024M, 1G)
- `disk_quota`: _Optional._ Disk limit (e.g. 256M, 1024M, 1G)

```yml
- put: cf-run-task
  resource: cf-env
  params:
    command: run-task
    app_name: myapp-ui
    task_command: "bundle exec rake db:migrate"
    task_name: migrate
    memory: 256M
    disk_quota: 1G
```

#### scale

Change or view the instance count, disk space limit, and memory limit for an app

- `org`: _Optional._ The organization to target (required if not set in the source config)
- `space`: _Optional._ The space to target (required if not set in the source config)
- `app_name`: _Required._ The name of the application
- `instances`: _Optional._ Number of instances
- `disk_quota`: _Optional._ Disk limit (e.g. 256M, 1024M, 1G)
- `memory`: _Optional._ Memory limit (e.g. 256M, 1024M, 1G)

```yml
- put: cf-scale
  resource: cf-env
  params:
    command: scale
    app_name: myapp-ui
    instances: 3
    disk_quota: 1G
    memory: 2G
```
