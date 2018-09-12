# Change log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 2.8.1 - 2018-09-11
### Fixed
- `push` command now properly handles `app_name` with spaces

### Changed
- refactored integration tests into multiple files targeting logical features (instead of a single 1,854 line file!)

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         | [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)         |

## 2.8.0 - 2018-08-26
### Changed
- `push` command now handles Docker images and private registries

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         | [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)         |

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
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.37.0](https://github.com/cloudfoundry/cli/releases/tag/v6.37.0)  |
| autopilot  | [0.0.6](https://github.com/contraband/autopilot/releases/tag/0.0.6) |
| yq         | [2.1.0](https://github.com/mikefarah/yq/releases/tag/2.1.0)         |

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
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.5.1 - 2018-04-03
### Fixed
- `create-service-broker` command now only targets an org and space if `space_scoped: true`
- Remove un-necessary cf_target call from `create-domain`

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

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
- Use parameter expansion in cf_* functions to check all required args and allow optional args
- Use array for dynamic argument building for cf cli calls to retain argument quoting
- Removed unused function: cf_create_org_if_not_exists
- Removed unused function: cf_create_space_if_not_exists

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.35.2](https://github.com/cloudfoundry/cli/releases/tag/v6.35.2)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.4.3 - 2018-02-23
### Fixed
- `create-user-provided-service` when checking if a ups already exists, the command now only checks the current space instead of every space the user has access to.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.4.2 - 2018-02-16
### Fixed
- `delete-service` command's `wait_for_service` now only checks the current space instead of every space the user has access to.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.4.1 - 2018-02-09
### Fixed
- `cf_trace: true` no longer messes up `cf` calls that are intended to capture the json output inside scripts. For now, we set `CF_TRACE=false` for all `cf` calls where we need to capture the output. I think there is a way to redirect the `CF_TRACE` output, but I couldn't figure it out with the way we do stdout and stderr redirects in the `out` script.  Until then, please note that you won't see the trace info *every* `cf` command used in the script.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

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
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.3.1 - 2018-01-08
### Fixed
- Fixed `enable-service-access` and `disable-service-access` both now properly treat `plan` and `access_org` as optional, thanks to a PR by [@legnoh](https://github.com/legnoh)
- Docs for `enable-service-access` and `disable-service-access` have been corrected to reference `service_broker` argument name (was incorrectly set to `service`).

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

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
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.32.0](https://github.com/cloudfoundry/cli/releases/tag/v6.32.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.2.1 - 2017-10-04
### Added
- Change log.
- Generate release notes from change log for github release.

### Changed
- `create-user-provided-service` command no longer fails if there is an existing *user provided service* by the same name.  **NOTE:** This is a departure from how the normal `cf cups ...` command works as it normally fails with an error:

  *Server error, status code: 400, error code: 60002, message: The service instance name is taken: my-cups-service*

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.2.0 - 2017-09-25
### Added
- `create-user-provided-service` command.

### Changed
- Fixed the docs in certain places to state that we 'target' orgs and spaces instead of 'create'.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.1.1 - 2017-09-19
### Fixed
- No longer use `echo -e` flag when processing params (which would expand escaped characters and result in invalid json), thanks to a PR by [@keymon](https://github.com/keymon)
- cf_login skip_ssl_validation param now defaults to `false`.

### Changed
- Integration test now parameterizes the cf connection settings so we can target different cf installs.
- Integration test now cleans-up previously failed tests.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.1.0 - 2017-08-21
### Added
- `create-user` command to create user with credentials or origin (e.g. ldap, provider-alias).
- `create-users-from-file` command to create users from a csv file.
- `delete-user` command.

### Fixed
- `skip_cert_check` is really optional now, thanks to a PR by [@ntdt](http://github.com/ntdt).

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 2.0.0 - 2017-05-23
### Added
- Learned how to run multiple instances of the same command.

### Removed
- Old deprecated command syntax.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 1.2.1 - 2017-05-02
### Fixed
- `zero-downtime-push` Properly handle environment variables passed as a single value or as a sequence or map.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 1.2.0 - 2017-05-02
### Fixed
- Put script now sets default TMPDIR if not set.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.26.0](https://github.com/cloudfoundry/cli/releases/tag/v6.26.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 1.1.0 - 2017-04-18
### Changed
- `zero-downtime-push` now supports adding environment variables.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.25.0](https://github.com/cloudfoundry/cli/releases/tag/v6.25.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
| yaml       | [1.10](https://github.com/mikefarah/yq/releases/tag/1.10)           |

## 1.0.2 - 2017-04-18
### Added
- `wait-for-service` commmand.

### Changed
- `create-service` command now supports `timeout` and `wait_for_service` params.

### Packaged Dependencies
| Dependency | Version                                                             |
|------------|:-------------------------------------------------------------------:|
| cf cli     | [6.25.0](https://github.com/cloudfoundry/cli/releases/tag/v6.25.0)  |
| autopilot  | [0.0.3](https://github.com/contraband/autopilot/releases/tag/0.0.3) |
