'use strict';

// Core modules
var exec = require('child_process').exec;

// External modules
var Bluebird = require('bluebird');
var semver   = require('semver');

// Misc
var pexec = Bluebird.promisify(exec);

var helper = module.exports = {
  parseArgs: function (args) {
    var result = {};

    if (args.skipPush) {
      result.skipPush = args.skipPush;
    }

    if (args.patch || args.bugfix || args.minor || args.major || !semver.valid(args._[0])) {
      var version = helper.getCurrentVersion();
      var release;

      if (args.bugfix || args.patch) {
        release = 'patch';
      } else if (args.minor) {
        release = 'minor';
      } else if (args.major) {
        release = 'major';
      } else {
        release = args._[0];
      }

      result.version = semver.inc(version, release);
    } else {
      result.version = args._[0];
    }

    return result;
  },

  validateVersion: function (args) {
    if (!semver.valid(args.version)) {
      var version = args.version || (args._ && args._[0]);
      throw new Error('Specified version is not valid: ' + version);
    } else if (semver.lte(args.version, helper.getCurrentVersion())) {
      throw new Error('Specified version is smaller than the current one: ' + args.version);
    }
  },

  exec: function (command, options) {
    return new Bluebird(function (resolve, reject) {
      exec(command, options || {}, function (err, stdout, stderr) {
        if (err) {
          reject(err);
        } else {
          resolve(stdout.trim().split('\n'), stderr);
        }
      });
    });
  },

  getCurrentVersion: function () {
    return require(process.cwd() + '/package.json').version;
  }
};
