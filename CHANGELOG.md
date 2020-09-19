# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 2.XX.X - Unreleased

### Added

- Introduced new tests (see `spec` folder) using the [shellspec](https://shellspec.info/) BDD testing framework. The existing home-grown test framework in the `itest` folder has served this project well, but it's time to move

### Changed

- Resource and test executions are now isolated from each other thanks to setting their own unique `CF_HOME` locations.

### Packaged Dependencies

| Dependency |                              Version                               |
| ---------- | :----------------------------------------------------------------: |
| cf cli     | [6.51.0](https://github.com/cloudfoundry/cli/releases/tag/v6.51.0) |
| cf7 cli    |  [7.0.2](https://github.com/cloudfoundry/cli/releases/tag/v7.0.2)  |
| yq         |    [3.3.2](https://github.com/mikefarah/yq/releases/tag/3.3.2)     |

## 2.21.0 - 2020-08-09

# Changed

- `enable-service-access` and `disable-service-access` commands now supports the `broker` option, thanks to a PR by [dominikmueller](https://github.com/dominikmueller)
- Updated to [cf cli v6.51.0](https://github.com/cloudfoundry/cli/releases/tag/v6.51.0)
- Updated to [cf7 cli v7.0.2](https://github.com/cloudfoundry/cli/releases/tag/v7.0.2)

### Packaged Dependencies

| Dependency |                              Version                               |
| ---------- | :----------------------------------------------------------------: |
| cf cli     | [6.51.0](https://github.com/cloudfoundry/cli/releases/tag/v6.51.0) |
| cf7 cli    |  [7.0.2](https://github.com/cloudfoundry/cli/releases/tag/v7.0.2)  |
| yq         |    [3.3.2](https://github.com/mikefarah/yq/releases/tag/3.3.2)     |

## 2.20.0 - 2020-07-09

# Changed

- `push` command now supports the `strategy` option when combined with using `cf_cli_version: 7`

### Packaged Dependencies

| Dependency |                              Version                               |
| ---------- | :----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0) |
| cf7 cli    |  [7.0.1](https://github.com/cloudfoundry/cli/releases/tag/v7.0.1)  |
| yq         |    [3.3.2](https://github.com/mikefarah/yq/releases/tag/3.3.2)     |

## 2.19.1 - 2020-07-08

### Fixed

- `run-task`, `add-network-policy`, `remove-network-policy`, `create-route`, `create-buildpack` commands now work using `cf_cli_version: 7`

### Packaged Dependencies

| Dependency |                              Version                               |
| ---------- | :----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0) |
| cf7 cli    |  [7.0.1](https://github.com/cloudfoundry/cli/releases/tag/v7.0.1)  |
| yq         |    [3.3.2](https://github.com/mikefarah/yq/releases/tag/3.3.2)     |

## 2.19.0 - 2020-06-29

### Added

- Introduced experimental support for `cf7` cli! This is enabled by configuring `cf_cli_version: 7` globally on the resource source configuration.

### Fixed

- The `environment_variables` handling introduced for the `push` command introduced in v2.18.1 wasn't properly placing the `env` node at the application level (it was placing it at the deprecated global level) with only one application in the manifest but no `app_name` declared. This has been corrected and the test case updated to properly check for this condition.

### Changed

- Major changes to `zero-downtime-push` command!!! The command has been refactored to no longer depend on the deprecated [autopilot](https://github.com/contraband/autopilot) plugin and now provides a "hand crafted" zero downtime push experience and supports `vars` and `vars_files` arguments, thanks to a PR by [shyamz-22](https://github.com/shyamz-22). It also now supports `docker_image`, `show_app_log` on failed pushes, the `no_start` flag, and `staging_timeout` and `startup_timeout` params. The `zero-downtime-push` integration tests have also received a major overhaul to ensure a seamless transition.
- `push` command now supports the `show_app_log` option to output app logs after a failed push (use with `app_name` option)
- `bind-route-service` command now supports the `path` option (used in combination with `hostname` and `domain` to specify the route to bind), thanks to a PR by [shyamz-22](https://github.com/shyamz-22)!
- We use Alpine Linux as the base image for `cf-cli-resource` when it runs inside of Concourse. With Alipine `v3.8` headed to [End of Support on 2020-05-01](https://wiki.alpinelinux.org/wiki/Alpine_Linux:Releases) it was time to update to Alpine `v3.11` which should keep us up-to-date till 2021-11-01.
- Removed `autopilot` cf cli plugin (see changes to `zero-downtime-push` command)
- Updated `yq` cli to version 3.2.1

### Packaged Dependencies

| Dependency |                              Version                               |
| ---------- | :----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0) |
| cf7 cli    |  [7.0.1](https://github.com/cloudfoundry/cli/releases/tag/v7.0.1)  |
| yq         |    [3.3.2](https://github.com/mikefarah/yq/releases/tag/3.3.2)     |

## 2.18.1 - 2020-03-31

### Fixed

- When `push`ing an app with `environment_variables` without a manifest, we create a temporary manifest that contains the `env:` attribute. This was being done at the global attribute level, resulting in cli deprecation warnings: `Deprecation warning: Specifying app manifest attributes at the top level is deprecated. Found: env.` This is now fixed by creating a manifest with the `env:` attribute properly set at the application level. No more deprecation warnings (thanks to a PR by [@destasys](https://github.com/destasys))

### Changed

- Replaced all direct calls to `cf` cli with a `cf::cf` wrapper function. This is the first pass at being able to specify which version of the cf cli you want to use (in preparation for testing the [cf7](https://github.com/cloudfoundry/cli#downloading-the-v7-beta-cli) version of the cli)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [3.2.1](https://github.com/mikefarah/yq/releases/tag/3.2.1)     |

## 2.18.0 - 2020-03-24

### Changed

- `push` command now supports setting `environment_variables` (thanks to a PR by [@lbenedix](https://github.com/nedenwalker))
- `set-env` command now supports setting multiple `environment_variables`. This deprecates the original `env_var_name` and `env_var_value` params.
- Updated `yq` cli to version 3.2.1

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [3.2.1](https://github.com/mikefarah/yq/releases/tag/3.2.1)     |

## 2.17.0 - 2020-02-27

This release introduces some major changes to the project structure. The `cf-cli-resource` has come a long way since its humble beginnings in early 2017 and it was about time to do some spring cleaning. Thankfully our test cases have ensured that we were able to make these changes with confidence. Check out the rest of the release notes for all the details.

### Added

- Added a [README](examples/README.md) for example pipelines.
- Added [example pipeline](examples/cf_home-auth/pipeline.yml) for `cf_home` usage.

### Fixed

- The `create-users-from-file` command now logs a warning (instead of an error) if the `Username` value is not set (since that's not a failing condition).

### Changed

- Updated to [cf cli v6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0)
- `add-network-policy` and `remove-network-policy` commands now support the `destination_org` and `destination_space` params for targeting a destination app in a different org and/or space.
- `create-service` command now supports the `broker` param to disambiguate if you have two services with the same name.
- Renamed `assets` folder to `resource`. This makes it simpler to locate scripts whether we are running tests locally or in a Docker image.
- Renamed `cf_*` functions to `cf::*` to follow the "package" naming convention.
- Moved all supporting function libraries to respective `resource/lib` and `itest/lib` folders.
- Refactored `resource/out` to invoke resource commands from separate files (see `resource/commands` folder). This should make adding new commands much cleaner and easier.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.49.0](https://github.com/cloudfoundry/cli/releases/tag/v6.49.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.16.0 - 2020-01-27

### Added

- `cf_home` param for supplying a `CF_HOME` folder which (in this initial release) allows for passing on a previously configured `.cf/config.json` file for CF API authentication (thanks to a PR by [@lbenedix](https://github.com/lbenedix))

### Changed

- `push` command now supports the `domain` param, thanks to a PR by [@vixus0](https://github.com/vixus0)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.45.0](https://github.com/cloudfoundry/cli/releases/tag/v6.45.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.15.2 - 2019-12-04

### Fixed

- `create-buildpack` now supports globbing for `path` param.

### Added

- Validation tests for validating error exit codes
- logging library

### Changed

- Completed [Operation Global Cleanup](https://github.com/nulldriver/cf-cli-resource/projects/1#card-23927144) to cleanup how global vars are used in the test scripts.
- Refactored pipeline to use [registry-image](https://github.com/concourse/registry-image-resource) and [vito/oci-build-task](https://github.com/vito/oci-build-task)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.45.0](https://github.com/cloudfoundry/cli/releases/tag/v6.45.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.15.1 - 2019-07-06

### Fixed

- `update-buildpack` now supports globbing for `path` param.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.45.0](https://github.com/cloudfoundry/cli/releases/tag/v6.45.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.15.0 - 2019-06-27

### Fixed

- `enable-service-access` and `disable-service-access` used a very mis-leading `service_broker` param to represent the name of the marketplace service to enable/disable. So, the `service_broker` param is now deprecated and is superseded by the new properly named `service` param.

### Added

- `create-buildpack` - Create a buildpack
- `update-buildpack` - Update a buildpack
- `delete-buildpack` - Delete a buildpack

### Changed

- Updated to [cf cli v6.45.0](https://github.com/cloudfoundry/cli/releases/tag/v6.45.0)
- Refactored `cf_functions.sh` to utilize the new `cf curl --fail` option for better error api error handling
- Quite a bit of test code cleanup

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.45.0](https://github.com/cloudfoundry/cli/releases/tag/v6.45.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.14.0 - 2019-06-02

### Changed

- `zero-downtime-push` command now supports the `stack` option

### Fixed

- Fixed `zero-downtime-push` where it had some problems with environment variables that were multi-line or started with a hyphen
- The optional `port` and `protocol` options for `add-network-policiy` are now really optional, thanks to a PR by [@rs017991](https://github.com/rs017991)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.42.0](https://github.com/cloudfoundry/cli/releases/tag/v6.42.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.3.0](https://github.com/mikefarah/yq/releases/tag/2.3.0)     |

## 2.13.0 - 2019-03-25

### Changed

- `push` command now supports `vars` and `vars_files` options for manifest variable substitution
- `push` command now supports `stack` option

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.42.0](https://github.com/cloudfoundry/cli/releases/tag/v6.42.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.12.0 - 2019-03-19

### Added

- `create-service-key` - Create key for a service instance (thanks to a PR by [@brentdemark](https://github.com/brentdemark))
- `delete-service-key` - Delete a service key (thanks to a PR by [@brentdemark](https://github.com/brentdemark))

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.42.0](https://github.com/cloudfoundry/cli/releases/tag/v6.42.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.11.0 - 2019-02-25

### Added

- `bind-route-service` command - Bind a service instance to an HTTP route

### Changed

- Updated to [cf cli v6.42.0](https://github.com/cloudfoundry/cli/releases/tag/v6.42.0)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.42.0](https://github.com/cloudfoundry/cli/releases/tag/v6.42.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.10.0 - 2019-01-22

### Added

- `set-env` command - Set an env variable for an app
- `update-service` command - Update a service instance
- `create-route` command - Create a url route in a space for later use
- `delete-route` command - Delete a route

### Changed

- `create-service` command now supports `update_service` param to update a service instance if it already exists, defaults to `false`.
- `push` command now supports additional options:
  - `startup_command`: Startup command, set to null to reset to default start command
  - `staging_timeout`: Max wait time for buildpack staging, in minutes
  - `startup_timeout`: Max wait time for app instance startup, in minutes
- The build pipeline has been updated to run the integration tests in parallel, reducing the test time from ~15 minutes down to ~2.5 minutes :-)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.40.0](https://github.com/cloudfoundry/cli/releases/tag/v6.40.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.9.1 - 2018-11-18

### Fixed

- `command_file` previously only worked by specifying an absolute file path. This is fixed to correctly support relative paths and the tests have been updated accordingly, thanks to a PR by [@renbeynolds](https://github.com/renbeynolds)
- Fixed `create-user-provided-service` example for specifying a `route_service_url`, thanks to a PR by [@eruvanos](https://github.com/eruvanos)
- `run-route-tests` now properly test if an app is mapped to a route

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.40.0](https://github.com/cloudfoundry/cli/releases/tag/v6.40.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.9.0 - 2018-10-21

### Added

- `share-service` command - Share a service instance with another space
- `unshare-service` command - Unshare a shared service instance from a space
- `rename` command - Rename an app
- Source configuration now supports `origin` for `username` & `password` authentication
- Source configuration now supports `client_id` and `client_secret` for authentication
- `command_file` support - You can now configure `command` or `commands` in an external yaml file, thanks to a PR by [@senglin](https://github.com/senglin)

### Changed

- Test cleanup now deletes orphaned service brokers from previously failed tests
- With the authentication changes in this release, the `cf_login` function was getting a bit overloaded, so it's now gone in favor of separate `cf_api`, `cf_auth_user`, and `cf_auth_client` functions
- Updated to [cf cli v6.40.0](https://github.com/cloudfoundry/cli/releases/tag/v6.40.0)
- Updated to [autopilot cf plugin v0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.40.0](https://github.com/cloudfoundry/cli/releases/tag/v6.40.0)  |
| autopilot  | [0.0.8](https://github.com/contraband/autopilot/releases/tag/0.0.8) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.8.3 - 2018-09-18

### Fixed

- `enable-service-access` and `disable-service-access` no longer error if you don't specify an org or space ('cause you don't have to!)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.8.2 - 2018-09-12

### Fixed

- `push` changes in 2.8.1 to support `app_name` with spaces accidentally broke `path` globbing. All fixed now (`run-app-tests` has been updated to test for this now), sorry for the inconvenience!

### Removed

- Version 2.8.1

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.8.1 - 2018-09-11 [YANKED]

### Fixed

- `push` command now properly handles `app_name` with spaces

### Changed

- refactored integration tests into multiple files targeting logical features (instead of a single 1,854 line file!)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.8.0 - 2018-08-26

### Changed

- `push` command now handles Docker images and private registries

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.7.0 - 2018-08-19

### Added

- `add-network-policy` command - Create policy to allow direct network traffic from one app to another
- `remove-network-policy` command - Remove network traffic policy of an app

### Changed

- `create-user-provided-service` command now updates the ups if it already exists
- Updated to [cf cli v6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)
- Updated to [autopilot cf plugin v0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6)
- Updated to [yq cli v2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         |     [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)     |

## 2.6.0 - 2018-05-15

### Added

- `stop` command - Stop an app
- `restart` command - Stop all instances of the app, then start them again. This causes downtime.
- `restage` command - Recreate the app's executable artifact using the latest pushed app files and the latest environment (variables, service bindings, buildpack, stack, etc.)
- `enable-feature-flag` command - Allow use of a feature
- `disable-feature-flag` command - Prevent use of a feature

### Changed

- Better cleanup of users created by tests
- The `cf_user_exists` function used in tests now handles result pagination

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.5.1 - 2018-04-03

### Fixed

- `create-service-broker` command now only targets an org and space if `space_scoped: true`
- Remove un-necessary cf_target call from `create-domain`

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.5.0 - 2018-04-02

### Added

- `scale` command - Change or view the instance count, disk space limit, and memory limit for an app
- `create-domain` command - Create a domain in an org for later use
- `delete-domain` command - Delete a domain
- `map-route` command - Add a url route to an app
- `unmap-route` command - Remove a url route from an app
- `run-task` command - Run a one-off task on an app, thanks to a PR by [@bigorangemachine](https://github.com/bigorangemachine)

### Changed

- Updated to cf cli v6.35.2

### General Code Cleanup

- Change tests to support Orgs and Spaces with spaces
- Add necessary variable quoting
- Remove un-necessary variable quoting
- Use parameter expansion in cf\_\* functions to check all required args and allow optional args
- Use array for dynamic argument building for cf cli calls to retain argument quoting
- Removed unused function: cf_create_org_if_not_exists
- Removed unused function: cf_create_space_if_not_exists

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.4.3 - 2018-02-23

### Fixed

- `create-user-provided-service` when checking if a ups already exists, the command now only checks the current space instead of every space the user has access to.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.4.2 - 2018-02-16

### Fixed

- `delete-service` command's `wait_for_service` now only checks the current space instead of every space the user has access to.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.4.1 - 2018-02-09

### Fixed

- `cf_trace: true` no longer messes up `cf` calls that are intended to capture the json output inside scripts. For now, we set `CF_TRACE=false` for all `cf` calls where we need to capture the output. I think there is a way to redirect the `CF_TRACE` output, but I couldn't figure it out with the way we do stdout and stderr redirects in the `out` script. Until then, please note that you won't see the trace info _every_ `cf` command used in the script.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.4.0 - 2018-02-08

### Added

- We now have a dedicated Cloud Foundry instance to use for integration testing (thanks Pivotal!!). This should help turn-around PRs and issues a little faster.
- Support `cf_trace`, `cf_dial_timeout` and `cf_trace` configurations for source and command params.
- `unbind-service` command - Unbind a service instance from an app

### Changed

- Updated docs to clarify the use of logical names for `put` steps.
- `delete-service` command now supports `wait_for_service` param for deleting asynchronous services.
- Refactored integration tests to default to PCF Dev for local testing while allowing for overriding by exporting env vars before running the test script.
- Added `test` job to pipeline to run the integration tests after the Docker image is built.
- Refactored service creation/binding/deletion tests to better focus on synchronous and asynchronous services.

### Fixed

- `wait-for-service` command errors if the service does not exist.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.3.1 - 2018-01-08

### Fixed

- Fixed `enable-service-access` and `disable-service-access` both now properly treat `plan` and `access_org` as optional, thanks to a PR by [@legnoh](https://github.com/legnoh)
- Docs for `enable-service-access` and `disable-service-access` have been corrected to reference `service_broker` argument name (was incorrectly set to `service`).

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.3.0 - 2017-11-14

### Added

- Output the `cf --version` in the logs.
- `create-service-broker` command - Create/Update a service broker
- `delete-service-broker` command - Delete a service broker
- `enable-service-access` command - Enable access to a service or service plan for one or all orgs
- `disable-service-access` command - Disable access to a service or service plan for one or all orgs

### Changed

- Updated `cf` cli to version 6.32.0. This paves the way for introducing some of the new `v3` commands (although we haven't implemented any yet...)
- Log messages have been cleaned up and now use color coded severity levels (in green and red, respectively): [INFO], [ERROR]

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.2.1 - 2017-10-04

### Added

- Change log.
- Generate release notes from change log for github release.

### Changed

- `create-user-provided-service` command no longer fails if there is an existing _user provided service_ by the same name. **NOTE:** This is a departure from how the normal `cf cups ...` command works as it normally fails with an error:

  _Server error, status code: 400, error code: 60002, message: The service instance name is taken: my-cups-service_

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.2.0 - 2017-09-25

### Added

- `create-user-provided-service` command.

### Changed

- Fixed the docs in certain places to state that we 'target' orgs and spaces instead of 'create'.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.1.1 - 2017-09-19

### Fixed

- No longer use `echo -e` flag when processing params (which would expand escaped characters and result in invalid json), thanks to a PR by [@keymon](https://github.com/keymon)
- cf_login skip_ssl_validation param now defaults to `false`.

### Changed

- Integration test now parameterizes the cf connection settings so we can target different cf installs.
- Integration test now cleans-up previously failed tests.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.1.0 - 2017-08-21

### Added

- `create-user` command to create user with credentials or origin (e.g. ldap, provider-alias).
- `create-users-from-file` command to create users from a csv file.
- `delete-user` command.

### Fixed

- `skip_cert_check` is really optional now, thanks to a PR by [@ntdt](http://github.com/ntdt).

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 2.0.0 - 2017-05-23

### Added

- Learned how to run multiple instances of the same command.

### Removed

- Old deprecated command syntax.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 1.2.1 - 2017-05-02

### Fixed

- `zero-downtime-push` Properly handle environment variables passed as a single value or as a sequence or map.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 1.2.0 - 2017-05-02

### Fixed

- Put script now sets default TMPDIR if not set.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 1.1.0 - 2017-04-18

### Changed

- `zero-downtime-push` now supports adding environment variables.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.25.0](https://github.com/cloudfoundry/cli/releases/tag/v6.25.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       |      [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)      |

## 1.0.2 - 2017-04-18

### Added

- `wait-for-service` commmand.

### Changed

- `create-service` command now supports `timeout` and `wait_for_service` params.

### Packaged Dependencies

| Dependency |                               Version                               |
| ---------- | :-----------------------------------------------------------------: |
| cf cli     | [6.25.0](https://github.com/cloudfoundry/cli/releases/tag/v6.25.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
