'use strict';

// Local modules
var helper = require('./misc');

module.exports = {
  updatePackage: function (args) {
    var command = 'npm version {{version}} -m "Bump to version: v{{version}}"';
    return helper.exec(command.replace(/\{\{version\}\}/g, args.version));
  },

  publishPackage: function () {
    return helper.exec('npm publish');
  }
};
