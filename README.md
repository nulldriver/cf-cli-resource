# cf cli Concourse Resource

[![CI Builds](https://wings.concourse.ci/api/v1/teams/sme-pcf-concourse/pipelines/cf-cli-resource/jobs/build/badge)](https://wings.concourse.ci/teams/sme-pcf-concourse/pipelines/cf-cli-resource)
[![Docker Pulls](https://img.shields.io/docker/pulls/pivotalpa/cf-cli-resource.svg)](https://hub.docker.com/r/pivotalpa/cf-cli-resource/)

An output only resource capable of running lots of Cloud Foundry cli commands.

## Source Configuration

* `api`: *Required.* The address of the Cloud Controller in the Cloud Foundry deployment.
* `username`: *Required.* The username used to authenticate.
* `password`: *Required.* The password used to authenticate.
* `skip_cert_check`: *Optional.* Check the validity of the CF SSL cert. Defaults to `false`.
* `org`: *Optional.* Sets the default organization to target (can be overridden in the params config).
* `space`: *Optional.* Sets the default space to target (can be overridden in the params config).
* `cf_color`: *Optional.* Set to `false` to not colorize cf output (can be overridden in the params config).
* `cf_dial_timeout`: *Optional.* Max wait time to establish a connection, including name resolution, in seconds (can be overridden in the params config).
* `cf_trace`: *Optional.* Set to `true` to print cf API request diagnostics to stdout (can be overridden in the params config).

```yml
resource_types:
- name: cf-cli-resource
  type: docker-image
  source:
    repository: pivotalpa/cf-cli-resource
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

*NOTE*: A common practice is to use different logical names for each `put` step and reuse the same `resource`.
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

*or* they can be combined in a single `put` step:

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


## Behavior

### `out`: Run a cf cli command.

Run cf command(s) on a Cloud Foundry installation.

#### create-org

Create an org

* `org`: *Optional.* The organization to create (required if not set in the source config)

```yml
  - put: cf-create-org
    resource: cf-env
    params:
      command: create-org
      org: myorg
```

#### delete-org

Delete an org

* `org`: *Optional.* The organization to delete (required if not set in the source config)

```yml
  - put: cf-delete-org
    resource: cf-env
    params:
      command: delete-org
      org: myorg
```

#### create-space

Create a space

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)

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

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to delete (required if not set in the source config)

```yml
  - put: cf-delete-space
    resource: cf-env
    params:
      command: delete-space
      org: myorg
      space: myspace
```

#### create-user

Create a new user

* `username`: *Required.* The user to create
* `password`: *Optional.* The password (must specify either `password` or `origin`)
* `origin`: *Optional.* The authentication origin (e.g. ldap, provider-alias) (must specify either `password` or `origin`)

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

* `file`: *Required.* The csv file containing the users

```yml
  - put: prepare-env
    resource: cf-env
    params:
      command: create-users-from-file
      file: somepath/users.csv
```

The format of the bulk load file:

| Username | Password | Org        | Space        | OrgManager | BillingManager | OrgAuditor | SpaceManager | SpaceDeveloper | SpaceAuditor |
| -------- | -------- | ---------- | -------------| ---------- | -------------- | ---------- | ------------ | -------------- | ------------ |
| user1    | S3cr3t   | org1       | dev          |      x     |        x       |      x     |       x      |        x       |       x      |
| user2    |          | org2       | dev          |            |        x       |      x     |              |        x       |       x      |
| user3    | S3cr3t   | org3       | dev          |            |                |      x     |              |                |       x      |
| user3    | S3cr3t   | org3       | test         |            |                |      x     |              |                |       x      |

Notes:

* The file must include the header row
* The file must be in comma separated value format
* You can specify the user more than once to assign multiple orgs/spaces
* If you omit the Org, no org or space roles will be assigned
* If you omit the Space, no space roles will be assigned

#### delete-user

Delete a user

* `username`: *Required.* The user to delete

```yml
  - put: prepare-env
    resource: cf-env
    params:
      command: delete-user
      username: j.smith@example.com
```

#### create-user-provided-service

Make a user-provided service instance available to CF apps

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_instance`: *Required.* The name to give the service instance
* Options: *Only specify one.*
  * `credentials`: Credentials, provided inline or in a file, to be exposed in the VCAP_SERVICES environment variable for bound applications
  * `syslog_drain_url`: URL to which logs for bound applications will be streamed
  * `route_service_url`: URL to which requests for bound routes will be forwarded. Scheme for this URL must be https

```yml
  - put: cf-create-user-provided-service
    resource: cf-env
    params:
      commands:
      # inline json
      - command: create-user-provided-service
        service_instance: my-db-mine
        credentials: '{"username":"admin","password":"pa55woRD"}'
      # json file
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
        syslog_drain_url: https://example.com
```

#### create-service

Create a service instance

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service`: *Required.* The marketplace service name to create
* `plan`: *Required.* The service plan name to create
* `service_instance`: *Required.* The name to give the service instance
* `configuration`: *Optional.* Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
* `tags`: *Optional.* User provided tags
* `timeout`: *Optional.* Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)
* `wait_for_service`: *Optional.* Wait for the asynchronous service to start. Defaults to `false`.

```yml
  - put: cf-create-service
    resource: cf-env
    params:
      command: create-service
      service: p-config-server
      plan: standard
      service_instance: my-config-server
      configuration: '{"count":3}'
      tags: 'list, of, tags'
      timeout: 300
      wait_for_service: true
```

#### delete-service

Delete a service instance

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_instance`: *Required.* The service instance to delete
* `wait_for_service`: *Optional.* Wait for the service to delete. Defaults to `false`.

```yml
  - put: cf-delete-service
    resource: cf-env
    params:
      command: delete-service
      service_instance: my-config-server
      wait_for_service: true
```

#### create-service-broker

Create/Update a service broker. If a service broker already exists, updates the existing service broker.

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_broker`: *Required.* The service broker name to create
* `username`: *Required.* The service broker username
* `password`: *Required.* The service broker password
* `url`: *Required.* The service broker url
* `space_scoped`: *Optional.* Make the broker's service plans only visible within the targeted space. Defaults to `false`.

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

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_broker`: *Required.* The service broker name to delete

```yml
  - put: cf-delete-service-broker
    resource: cf-env
    params:
      command: delete-service-broker
      service_broker: some-service
```

#### wait-for-service

Wait for a service instance to start

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_instance`: *Required.* The service instance to wait for
* `timeout`: *Optional.* Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)

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

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_broker`: *Required.* The marketplace service name to enable
* `access_org`: *Optional.* Enable access for a specified organization
* `plan`: *Optional.* Enable access to a specified service plan

```yml
  - put: cf-enable-service-access
    resource: cf-env
    params:
      command: enable-service-access
      service_broker: some-service
      access_org: myorg
      plan: simple
```

#### disable-service-access

Disable access to a service or service plan for one or all orgs

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `service_broker`: *Required.* The marketplace service name to disable
* `access_org`: *Optional.* Disable access for a specified organization
* `plan`: *Optional.* Disable access to a specified service plan

```yml
  - put: cf-disable-service-access
    resource: cf-env
    params:
      command: disable-service-access
      service_broker: some-service
      access_org: myorg
      plan: simple
```

#### bind-service

Bind a service instance to an app

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The application to bind to the service
* `service_instance`: *Required.* The service instance to bind to the application
* `configuration`: *Optional.* Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.

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

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The application to unbind from the service instance
* `service_instance`: *Required.* The service instance to unbind from the application

```yml
  - put: cf-unbind-service
    resource: cf-env
    params:
      command: unbind-service
      app_name: myapp-ui
      service_instance: mydb
```

#### push

Push a new app or sync changes to an existing app

*NOTE*: A manifest can be used to specify values for required parameters. Any parameters specified will override manifest values.

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `hostname`: *Optional.* Hostname (e.g. my-subdomain)
* `memory`: *Optional.* Memory limit (e.g. 256M, 1024M, 1G)
* `disk_quota`: *Optional.* Disk limit (e.g. 256M, 1024M, 1G)
* `instances`: *Optional.* Number of instances
* `path`: *Optional.* Path to app directory or to a zip file of the contents of the app directory
* `buildpack`: *Optional.* Custom buildpack by name (e.g. my-buildpack) or Git URL (e.g. 'https://github.com/cloudfoundry/java-buildpack.git') or Git URL with a branch or tag (e.g. 'https://github.com/cloudfoundry/java-buildpack.git#v3.3.0' for 'v3.3.0' tag). To use built-in buildpacks only, specify 'default' or 'null'
* `manifest`: *Optional.* Path to manifest
* `no_start`: *Optional.* Do not start an app after pushing. Defaults to `false`.

```yml
  - put: cf-push
    resource: cf-env
    params:
      command: push
      app_name: myapp-ui
      hostname: myapp
      memory: 512M
      disk_quota: 1G
      instances: 1
      path: path/to/myapp-*.jar
      buildpack: java_buildpack
      manifest: path/to/manifest.yml
      no_start: true
```

#### zero-downtime-push

Push a single app using the [autopilot plugin](https://github.com/contraband/autopilot).

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `manifest`: *Required.* Path to a application manifest file.
* `path`: *Optional.* Path to the application to push. If this isn't set then it will be read from the manifest instead.
* `current_app_name`: *Optional.* This should be the name of the application that this will re-deploy over. If this is set the resource will perform a zero-downtime deploy.
* `environment_variables`: *Optional.*  Environment variable key/value pairs to add to the manifest.

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
```

#### start

Start an app

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `staging_timeout`: *Optional.* Max wait time for buildpack staging, in minutes
* `startup_timeout`: *Optional.* Max wait time for app instance startup, in minutes

```yml
  - put: cf-start
    resource: cf-env
    params:
      command: start
      app_name: myapp-ui
      staging_timeout: 15
      startup_timeout: 5
```

#### delete

Delete an app

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `delete_mapped_routes`: *Optional.* Delete any mapped routes. Defaults to `false`.

```yml
  - put: cf-delete
    resource: cf-env
    params:
      command: delete
      app_name: myapp-ui
      delete_mapped_routes: true
```

#### run-task

Run task on an app

* `org`: *Optional.* The organization to target (required if not set in the source config)
* `space`: *Optional.* The space to target (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `task`: *Required.* The task to be ran
* `task_name`: *Optional.* The task name if you wish to name your task

```yml
  - put: cf-run-task
    resource: cf-env
    params:
      command: run-task
      app_name: myapp-ui
      task_name: migrate
      task: bundle exec rake db:migrate
```
