'use strict';

// 3rd-party modules
var Bluebird = require('bluebird');
var xtend    = require('xtend');

// Local modules
var releaseTools = require('../lib/index');
var support      = require('../lib/support');

module.exports = {
  init: function (functionName) {
    var argv = support.cli.init();
    var result = Bluebird.resolve(argv);

    if (argv.auto) {
      result = result
        .then(autoDetectVersion(argv.autoFallback))
        .then(function (detectedVersion) {
          return xtend(argv, detectedVersion);
        });
    }

    return result.then(function (args) {
      releaseTools.npm[functionName](support.misc.parseArgs(args));
    }).catch(function (e) {
      console.error((e.message || e).trim());
      process.exit(1);
    });
  }
};

function autoDetectVersion (fallback) {
  return function () {
    return support.git.getCommitsSinceLastVersion().then(function (commits) {
      return support.git.detectChangeType(commits, fallback);
    });
  }
}
