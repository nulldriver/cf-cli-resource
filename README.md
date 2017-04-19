# cf cli Concourse Resource

[![ci.anvil.pcfdemo.com](https://ci.anvil.pcfdemo.com/api/v1/teams/pcrocker/pipelines/cf-cli-resource/jobs/build/badge)](https://ci.anvil.pcfdemo.com/teams/pcrocker/pipelines/cf-cli-resource) [docker](https://hub.docker.com/r/patrickcrocker/cf-cli-resource/)

An output only resource capable of running lots of Cloud Foundry cli commands.

## Source Configuration

* `api`: *Required.* The address of the Cloud Controller in the Cloud Foundry deployment.
* `username`: *Required.* The username used to authenticate.
* `password`: *Required.* The password used to authenticate.
* `skip_cert_check`: *Optional.* Check the validity of the CF SSL cert. Defaults to `false`.
* `org`: *Optional.* Sets the default organization to target (can be overridden in the params config).
* `space`: *Optional.* Sets the default space to target (can be overridden in the params config).

```
resource_types:
- name: cf-cli-resource
  type: docker-image
  source:
    repository: patrickcrocker/cf-cli-resource
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

This resource is capable of running single commands in separate `put` steps:

```
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

```
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

```
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

```
  - put: cf-create-org
    resource: cf-env
    params:
      command: create-org
      org: myorg
```

#### delete-org

Delete an org

* `org`: *Optional.* The organization to create (required if not set in the source config)

```
  - put: cf-delete-org
    resource: cf-env
    params:
      command: delete-org
      org: myorg
```

#### create-space

Create a space

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)

```
  - put: cf-create-space
    resource: cf-env
    params:
      command: create-space
      org: myorg
      space: myspace
```

#### delete-space

Delete a space

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)

```
  - put: cf-delete-space
    resource: cf-env
    params:
      command: delete-space
      org: myorg
      space: myspace
```

#### create-service

Create a service instance

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `service`: *Required.* The marketplace service name to create
* `plan`: *Required.* The service plan name to create
* `service_instance`: *Required.* The name to give the service instance
* `configuration`: *Optional.* Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.
* `tags`: *Optional.* User provided tags
* `timeout`: *Optional.* Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)
* `wait_for_service`: *Optional.* Wait for the asynchronous service to start. Defaults to `false`.

```
  - put: cf-create-service
    resource: cf-env
    params:
      command: create-service,
      service: p-config-server,
      plan: standard,
      service_instance: my-config-server,
      configuration: '{"count":3}',
      tags: 'list, of, tags',
      timeout: 300,
      wait_for_service: true
```

#### wait-for-service

Wait for a service instance to start

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `service_instance`: *Required.* The service instance to wait for
* `timeout`: *Optional.* Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)

```
  - put: cf-wait-for-service
    resource: cf-env
    params:
      command: wait-for-service,
      service_instance: my-config-server,
      timeout: 300
```

#### delete-service

Delete a service instance

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `service_instance`: *Required.* The service instance to delete

```
  - put: cf-delete-service
    resource: cf-env
    params:
      command: delete-service,
      service_instance: my-config-server
```

#### bind-service

Bind a service instance to an app

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `app_name`: *Required.* The application to bind the service to
* `service_instance`: *Required.* The service instance to bind to the application
* `configuration`: *Optional.* Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.

```
  - put: cf-bind-service
    resource: cf-env
    params:
      command: bind-service,
      app_name: myapp-ui
      service_instance: mydb,
      configuration: '{"permissions":"read-only"}',
```

#### push

Push a new app or sync changes to an existing app

*NOTE*: A manifest can be used to specify values for required parameters. Any parameters specified will override manifest values.

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `hostname`: *Optional.* Hostname (e.g. my-subdomain)
* `memory`: *Optional.* Memory limit (e.g. 256M, 1024M, 1G)
* `disk_quota`: *Optional.* Disk limit (e.g. 256M, 1024M, 1G)
* `instances`: *Optional.* Number of instances
* `path`: *Optional.* Path to app directory or to a zip file of the contents of the app directory
* `buildpack`: *Optional.* Custom buildpack by name (e.g. my-buildpack) or Git URL (e.g. 'https://github.com/cloudfoundry/java-buildpack.git') or Git URL with a branch or tag (e.g. 'https://github.com/cloudfoundry/java-buildpack.git#v3.3.0' for 'v3.3.0' tag). To use built-in buildpacks only, specify 'default' or 'null'
* `manifest`: *Optional.* Path to manifest
* `no_start`: *Optional.* Do not start an app after pushing. Defaults to `false`.

```
  - put: cf-push
    resource: cf-env
    params:
      command: push,
      app_name: myapp-ui,
      hostname: myapp,
      memory: 512M,
      disk_quota: 1G,
      instances: 1,
      path: path/to/myapp-*.jar,
      buildpack: java_buildpack,
      manifest: path/to/manifest.yml,
      no_start: true
```

#### zero-downtime-push

Push a single app using the [autopilot plugin](https://github.com/contraband/autopilot).

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `manifest`: *Required.* Path to a application manifest file.
* `path`: *Optional.* Path to the application to push. If this isn't set then it will be read from the manifest instead.
* `current_app_name`: *Optional.* This should be the name of the application that this will re-deploy over. If this is set the resource will perform a zero-downtime deploy.
* `environment_variables`: *Optional.*  Environment variable key/value pairs to add to the manifest.

```
  - put: cf-zero-downtime-push
    resource: cf-env
    params:
      command: zero-downtime-push,
      manifest: path/to/manifest.yml,
      path: path/to/myapp-*.jar,
      current_app_name: myapp-ui,
      environment_variables:
        key: value
        key2: value2
```

#### start

Start an app

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `staging_timeout`: *Optional.* Max wait time for buildpack staging, in minutes
* `startup_timeout`: *Optional.* Max wait time for app instance startup, in minutes

```
  - put: cf-start
    resource: cf-env
    params:
      command: start,
      app_name: myapp-ui,
      staging_timeout: 15,
      startup_timeout: 5
```

#### delete

Delete an app

* `org`: *Optional.* The organization to create (required if not set in the source config)
* `space`: *Optional.* The space to create (required if not set in the source config)
* `app_name`: *Required.* The name of the application
* `delete_mapped_routes`: *Optional.* Delete any mapped routes. Defaults to `false`.

```
  - put: cf-delete
    resource: cf-env
    params:
      command: delete,
      app_name: myapp-ui,
      delete_mapped_routes: true
```
