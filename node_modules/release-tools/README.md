# release-tools [![Build Status](https://travis-ci.org/sdepold/release-tools.svg?branch=master)](https://travis-ci.org/sdepold/release-tools)

A tiny collection of release helpers that will help you bumping and publishing your package without too much hassles.

The projects ships a bunch of source code that get's used by very thin CLI wrappers. This way it is possible to actually use the sources independently from the command line, which can be handy if you want to integrate the logic into your own work flow.

## Installation

```
npm install -g release-tools
```

## Executables

Right now this project is very `npm` focussed but could in theory be used with every other dependency management tool as well.

### npm_bump

This executable is doing the following steps:

* It checks if your project contains a `CHANGELOG.md` file.
* If there is a changelog, it will check if the changelog contains the needle `## Upcoming` and replaces it with the new version and the current timestamp.
* If there is a changelog, it will commit the changes in changelog with the commit message `Add changes in version: v<version>`.
* It will now run `npm version` (which sets the version of your package.json to the new value), commit the change with the commit message `Bump to version: v<version>` and finally create a tag for the new version á la `v<version>`.
* Finally it pushes your changes and your tags to the remote server (via git).

#### Usage

```
npm_bump 1.2.3 # Usage with a fixed version
npm_bump --bugfix # Usage with options
```

#### Options

- `--bugfix`, `--patch` increases the third fragment of the version string (e.g. 1.2.3 to 1.2.4)
- `--minor` increases the second fragment of the version string and sets the third fragment to 0 (e.g. 1.2.3 to 1.3.0)
- `--major` increases the first fragment of the version string and sets the second and third fragment to 0 (e.g. 1.2.3 to 2.0.0)
- `--skip-push` will disable the pushing to the remote git server
- `--auto` enables automatic version detection. See below for more information
- `--auto-fallback` defines the to-be-bumped fragment in case of failing `auto` detection

### npm_release

This executable is doing the following steps:

- Call `npm_bump`. See the above steps.
- Release the package to npm via `npm publish`.

### Automatic change type detection

The flag `--auto` will parse the commits since the last git tag and checks the
subject and the body of the commit messages for some specific markers:

- `[major]` will generate a major version bump
- `[minor]`, `[feature]` will generate a minor version bump
- `[patch]`, `[bugfix]`, `[fix]`  will generate a patch version bump

If no change type is detected – because the markers are missing – you can also
specify a fallback type which is picked up in such cases:

```
npm_release --auto --auto-fallback minor
```

This will bump the minor version in case no marker has been found.

#### Example

Let's assume your lib is currently on version 1.0.0 (aka the package.json contains that particular version
number and a git tag `v1.0.0` exists). You now commit with the following messages:

```
[feature] Add new functionality
[patch] Fix readme
```

If you run `npm_release --auto` now, it will bump the second version fragment aka
set the version to `1.1.0`. This happens because of the `[feature]` in one of the
git commit message.

## Exported functions

### npm.bump
This function is called by `npm_bump` and expects an object as first parameter:

```javascript
var releaseTools = require('release-tools');

releaseTools.npm.bump({ version: '1.2.3' }); // Change version to a specific value.
releaseTools.npm.bump({ bugfix: true });     // Change version to next bugfix version.
releaseTools.npm.bump({ minor: true });      // change version to next minor release.
releaseTools.npm.bump({ major: true });      // Change version to next major release.
```

### npm.release
This function is called by `npm_release` and expects an object as first parameter:

```javascript
releaseTools.npm.release({ version: '1.2.3' }); // Change version to a specific value.
releaseTools.npm.release({ bugfix: true });     // Change version to next bugfix version.
releaseTools.npm.release({ minor: true });      // change version to next minor release.
releaseTools.npm.release({ major: true });      // Change version to next major release.
```

## One word about changelogs

Many of my projects are (roughly) following the schema of [keepachangelog](http://keepachangelog.com/).

## License
MIT
