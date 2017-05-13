'use strict';

var Bluebird = require('bluebird');
var helper = require('./misc');

var LOG_SEPARATOR = '<<-->>';

var git = module.exports = {
  push: function () {
    return helper.exec('git push');
  },

  pushTags: function () {
    return helper.exec('git push --tags');
  },

  getCommitsSinceLastVersion: function () {
    var currentVersion = 'v' + helper.getCurrentVersion();
    var ignoreScope = currentVersion === 'v0.0.0';
    var tagCommand = 'git show ' + currentVersion;
    var logAllCommand = 'git log --pretty=format:"%s' + LOG_SEPARATOR + '%b"'
    var logScopeCommand = logAllCommand + ' ' + currentVersion + '..HEAD';
    var logCommand = ignoreScope ? logAllCommand : logScopeCommand;

    var result = Bluebird.resolve();

    if (!ignoreScope) {
      result = result.then(function () {
        return helper.exec(tagCommand).catch(function () {
          throw new Error('Unable to find git tag: ' + currentVersion);
        });
      });
    }

    return result.then(function () {
      return helper.exec(logCommand).then(git.parseGitCommits);;
    });
  },

  parseGitCommits: function (commits) {
    return commits.filter(function (commit) {
      return commit.trim() !== '';
    }).map(function (commit) {
      var data = commit.split(LOG_SEPARATOR);

      return addChangeType({ subject: data[0], body: data[1] || '' });
    });
  },

  detectChangeType: function (commits, fallback) {
    var changeTypes = commits.reduce(function (acc, commit) {
      if (commit.changeType) {
        acc[commit.changeType] = true;
      }

      return acc;
    }, { major: false, minor: false, patch: false });
    var changeTypeDetected = changeTypes.major || changeTypes.minor || changeTypes.patch;

    if (changeTypes.major || (!changeTypeDetected && (fallback === 'major'))) {
      return { major: true };
    } else if (changeTypes.minor || (!changeTypeDetected && (fallback === 'minor'))) {
      return { minor: true };
    } else if (changeTypes.patch || (!changeTypeDetected && (fallback === 'patch'))) {
      return { patch: true };
    } else {
      throw new Error('No change type detected and no fallback defined!');
    }
  }
};

function isInCommit (commit) {
  return function (needle) {
    return (commit.subject + commit.body).indexOf('[' + needle + ']') > -1;
  }
}

function isMajorChange (commit) {
  return ['major'].some(isInCommit(commit));
}

function isMinorChange (commit) {
  return ['minor', 'feature'].some(isInCommit(commit));
}

function isPatchChange (commit) {
  return ['patch', 'bugfix', 'fix'].some(isInCommit(commit));
}

function getChangeType (commit) {
  if (isMajorChange(commit)) {
    return 'major';
  } else if (isMinorChange(commit)) {
    return 'minor';
  } else if (isPatchChange(commit)) {
    return 'patch';
  }
}

function addChangeType (commit) {
  commit.changeType = getChangeType(commit);

  return commit;
}
