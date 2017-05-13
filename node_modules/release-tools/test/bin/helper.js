'use strict';

var Bluebird = require('bluebird');
var exec = require('../../lib/support/misc').exec;
var testDir = "/tmp/release-tools-test";

function execGit (gitCommand, options) {
  return exec('git -c "user.name=sdepold" -c "user.email=sdepold@dev.null" ' + gitCommand, options);
}

var helper = module.exports = {
  bumpAndGetVersion: function (options) {
    options = options || {};

    return helper.prepare(options).then(function () {
      return helper.callBump(options);
    }).then(function () {
      return helper.readVersion();
    });
  },

  prepare: function (options) {
    var packageVersion = options.packageVersion || '0.0.0';
    
    return exec('rm -rf ' + testDir).then(function () {
      return exec('mkdir ' + testDir);
    }).then(function () {
      return exec('echo "{\\"version\\":\\"' + packageVersion + '\\"}" > ' + testDir + '/package.json');
    }).then(function () {
      return execGit('init .', { cwd: testDir });
    }).then(function () {
      return helper.createCommits(options.commits || [])
    });
  },

  createCommits: function (commits) {
    return Bluebird.map(commits, function (commit) {
      var message = (commit.subject + '\n\n' + (commit.body || '')).trim();
      var commitCommand = 'commit --allow-empty --message "' + message + '"';

      return execGit(commitCommand, { cwd: testDir }).then(function () {
        if (commit.tag) {
          return execGit('tag ' + commit.tag, { cwd: testDir });
        }
      });
    }, {
      concurrency: 1
    });
  },

  callBump: function (options) {
    options = options || {};

    var command = process.cwd() + '/bin/npm_bump.js --skip-push ' + (options.args || '');

    return exec(command, { cwd: testDir });
  },

  readVersion: function () {
    delete require.cache[require.resolve(testDir + '/package.json')];
    return require(testDir + '/package.json').version;
  }
};
