'use strict';

// External modules
var Bluebird = require('bluebird');

// Local modules
var Support = require('./support');

module.exports = {
  bump: function (args) {
    console.log('Bumping to version: v' + args.version + '\n');

    return Bluebird
      .resolve(args)
      .tap(logWrap('Evaluating the version', Support.misc.validateVersion))
      .tap(logWrap('Updating the changelog', Support.changelog.update))
      .tap(logWrap('Updating the package', Support.npm.updatePackage))
      .tap(logWrap('Pushing changes', Support.git.push, args.skipPush))
      .tap(logWrap('Pushing tags', Support.git.pushTags, args.skipPush));
  },

  release: function (args) {
    return this
      .bump(args)
      .tap(logWrap('Publishing package', Support.npm.publishPackage));
  }
};

function logWrap (s, fun, skip) {
  return function () {
    var args = [].slice.apply(arguments);

    return Bluebird
      .resolve()
      .then(function () {
        process.stdout.write(s + ' ... ');
      })
      .then(function () {
        if (!skip) {
          return fun.apply(null, args);
        }
      })
      .then(function () {
        console.log(skip ? 'skipped.' : 'done.');
      })
      .catch(function (e) {
        console.log('failed:');
        console.log(e);

        throw e;
      });
  };
}
