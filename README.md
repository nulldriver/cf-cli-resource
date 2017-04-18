# cf cli Concourse Resource

[![ci.anvil.pcfdemo.com](https://ci.anvil.pcfdemo.com/api/v1/teams/pcrocker/pipelines/cf-cli-resource/jobs/build/badge)](https://ci.anvil.pcfdemo.com/teams/pcrocker/pipelines/cf-cli-resource) [docker](https://hub.docker.com/r/patrickcrocker/cf-cli-resource/)

An output only resource capable of running lots of cf cli commands to a Cloud Foundry deployment.

## Source Configuration

* `api`: *Required.* The address of the Cloud Controller in the Cloud Foundry deployment.
* `username`: *Required.* The username used to authenticate.
* `password`: *Required.* The password used to authenticate.
* `skip_cert_check`: *Optional.* Check the validity of the CF SSL cert. Defaults to `false`.

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

## Behavior

### `out`: Run a cf cli command.

Deploy the artifact to the Maven Repository Manager.

#### create_org

Create an org

* `org`: *Required.* The organization to create

```
  - put: cf-create-org
    resource: cf-env
    params:
      create_org:
        org: myorg
```

#### delete_org

Delete an org

* `org`: *Required.* The organization to delete

```
  - put: cf-delete-org
    resource: cf-env
    params:
      delete_org:
        org: myorg
```

#### create_space

Create a space

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to create

```
  - put: cf-create-space
    resource: cf-env
    params:
      create_space:
        org: myorg
        space: myspace
```

#### delete_space

Delete a space

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to delete

```
  - put: cf-delete-space
    resource: cf-env
    params:
      delete_space:
        org: myorg
        space: myspace
```

#### create_service

Create a service instance

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
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
      create_service:
        org: myorg,
        space: myspace,
        service: p-config-server,
        plan: standard,
        service_instance: my-config-server,
        configuration: '{"count":3}',
        tags: 'list, of, tags',
        timeout: 300,
        wait_for_service: true
```

#### wait_for_service

Wait for a service instance to start

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `service_instance`: *Required.* The service instance to wait for
* `timeout`: *Optional.* Max wait time for service creation, in seconds. Defaults to `600` (10 minutes)

```
  - put: cf-wait-for-service
    resource: cf-env
    params:
      wait_for_service:
        org: myorg,
        space: myspace,
        service_instance: my-config-server,
        timeout: 300
```

#### delete_service

Delete a service instance

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `service_instance`: *Required.* The service instance to delete

```
  - put: cf-delete-service
    resource: cf-env
    params:
      delete_service:
        org: myorg,
        space: myspace,
        service_instance: my-config-server
```

#### bind_service

Bind a service instance to an app

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `app_name`: *Required.* The application to bind the service to
* `service_instance`: *Required.* The service instance to bind to the application
* `configuration`: *Optional.* Valid JSON object containing service-specific configuration parameters, provided either in-line or in a file. For a list of supported configuration parameters, see documentation for the particular service offering.

```
  - put: cf-bind-service
    resource: cf-env
    params:
      bind_service:
        org: myorg,
        space: myspace,
        app_name: myapp-ui
        service_instance: mydb,
        configuration: '{"permissions":"read-only"}',
```

#### push

Push a new app or sync changes to an existing app

*NOTE*: A manifest can be used to specify values for required parameters. Any parameters specified will override manifest values.

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
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
      push:
        org: myorg,
        space: myspace,
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

#### zero_downtime_push

Push a single app using the [autopilot plugin](https://github.com/contraband/autopilot).

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `manifest`: *Required.* Path to a application manifest file.
* `path`: *Optional.* Path to the application to push. If this isn't set then it will be read from the manifest instead.
* `current_app_name`: *Optional.* This should be the name of the application that this will re-deploy over. If this is set the resource will perform a zero-downtime deploy.

```
  - put: cf-zero-downtime-push
    resource: cf-env
    params:
      zero_downtime_push:
        org: myorg,
        space: myspace,
        manifest: path/to/manifest.yml,
        path: path/to/myapp-*.jar,
        current_app_name: myapp-ui
```

#### start

Start an app

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `app_name`: *Required.* The name of the application
* `staging_timeout`: *Optional.* Max wait time for buildpack staging, in minutes
* `startup_timeout`: *Optional.* Max wait time for app instance startup, in minutes

```
  - put: cf-start
    resource: cf-env
    params:
      start:
        org: myorg,
        space: myspace,
        app_name: myapp-ui,
        staging_timeout: 15,
        startup_timeout: 5
```

#### delete

Delete an app

* `org`: *Required.* The organization to target
* `space`: *Required.* The space to target
* `app_name`: *Required.* The name of the application
* `delete_mapped_routes`: *Optional.* Delete any mapped routes. Defaults to `false`.

```
  - put: cf-delete
    resource: cf-env
    params:
      delete:
        org: myorg,
        space: myspace,
        app_name: myapp-ui,
        delete_mapped_routes: true
```
