# Change log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 2.4.1 - 2018-02-09
### Fixed
- `cf_trace: true` no longer messes up `cf` calls that are intended to capture the json output inside scripts. For now, we set `CF_TRACE=false` for all `cf` calls where we need to capture the output. I think there is a way to redirect the `CF_TRACE` output, but I couldn't figure it out with the way we do stdout and stderr redirects in the `out` script.  Until then, please note that you won't see the trace info *every* `cf` command used in the script.

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

## 2.3.1 - 2018-01-08
### Fixed
- Fixed `enable-service-access` and `disable-service-access` both now properly treat `plan` and `access_org` as optional, thanks to a PR by [@legnoh](https://github.com/legnoh)
- Docs for `enable-service-access` and `disable-service-access` have been corrected to reference `service_broker` argument name (was incorrectly set to `service`).

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

## 2.2.1 - 2017-10-04
### Added
- Change log.
- Generate release notes from change log for github release.

### Changed
- `create-user-provided-service` command no longer fails if there is an existing *user provided service* by the same name.  **NOTE:** This is a departure from how the normal `cf cups ...` command works as it normally fails with an error:

  *Server error, status code: 400, error code: 60002, message: The service instance name is taken: my-cups-service*

## 2.2.0 - 2017-09-25
### Added
- `create-user-provided-service` command.

### Changed
- Fixed the docs in certain places to state that we 'target' orgs and spaces instead of 'create'.

## 2.1.1 - 2017-09-19
### Fixed
- No longer use `echo -e` flag when processing params (which would expand escaped characters and result in invalid json), thanks to a PR by [@keymon](https://github.com/keymon)
- cf_login skip_ssl_validation param now defaults to `false`.

### Changed
- Integration test now parameterizes the cf connection settings so we can target different cf installs.
- Integration test now cleans-up previously failed tests.

## 2.1.0 - 2017-08-21
### Added
- `create-user` command to create user with credentials or origin (e.g. ldap, provider-alias).
- `create-users-from-file` command to create users from a csv file.
- `delete-user` command.

### Fixed
- `skip_cert_check` is really optional now, thanks to a PR by [@ntdt](http://github.com/ntdt).

## 2.0.0 - 2017-05-23
### Added
- Learned how to run multiple instances of the same command.

### Removed
- Old deprecated command syntax.

## 1.2.1 - 2017-05-02
### Fixed
- `zero-downtime-push` Properly handle environment variables passed as a single value or as a sequence or map.

## 1.2.0 - 2017-05-02
### Fixed
- Put script now sets default TMPDIR if not set.

## 1.1.0 - 2017-04-18
### Changed
- `zero-downtime-push` now supports adding environment variables.

## 1.0.2 - 2017-04-18
### Added
- `wait-for-service` commmand.

### Changed
- `create-service` command now supports `timeout` and `wait_for_service` params.
