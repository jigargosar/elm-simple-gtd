# Change Log
All notable changes to this project will be documented in this file.

## v2.5.2 - 2017-02-01
### Fixed
- Fix version detection in parsed logs

## v2.5.1 - 2017-01-30
### Fixed
- Don't fail when git hooks are logging to stderr.

## v2.5.0 - 2017-01-24
### Added
- The flag `auto` automatically detects which version fragment to bump.

## v2.4.2 - 2015-07-16
### Changed
- Log upcoming version
- Properly handle --patch

## v2.4.1 - 2015-07-16
### Added
- The flag `patch`

## v2.4.0 - 2015-03-13
### Added
- Accept semver keywords as versions

## v2.3.0 - 2015-03-11
### Added
- Validate the version string

### Changed
- Use `semver` for the version bumping
- Ensure that the new version is bigger than the current one

## v2.2.0 - 2015-03-09
### Added
- Support for the changelog needle `Unreleased`

## v2.1.0 - 2015-03-04
### Added
- `--bugfix` flag that bumps to the next bugfix version
- `--minor` flag that bumps to the next minor version
- `--major` flag that bumps to the next major version

## v2.0.7 - 2015-03-03
### Changed
- Make npm_bump and npm_release DRY.

## v2.0.6 - 2015-03-03
### Changed
- Fix npm_bump. It wasn't able to parse the version

## v2.0.5 - 2015-03-02
### Changed
- Fix iojs build on travis

## v2.0.4 - 2015-03-02
### Removed
- Duplicate call for commit changelog

## v2.0.3 - 2015-03-02
### Changed
- Log errors

## v2.0.2 - 2015-03-02
### Added
- Logging

## v2.0.1 - 2015-03-02
### Changed
- Fix tests

## v2.0.0 - 2015-03-02
### Added
- Travis build
- Node.JS scripts
- Tests
- Changelog substitution

### Removed
- Bash scripts

## 1.1.0 - 2015-02-25
### Changed
- Add git push to actually add changes to the remote branch
- Omit output of commands

## 1.0.2 - 2015-02-25
### Added
- Date generation

### Changed
- Version replacement in change log

## 1.0.1 - 2015-02-25
### Changed
- Introduce bash version of npm_bump

## 1.0.0 - 2015-02-25
### Added
- Initial versions written in Ruby
