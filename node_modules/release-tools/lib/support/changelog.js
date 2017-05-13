'use strict';

// Core modules
var fs = require('fs');
var path = require('path');

// 3rd-party modules
var Bluebird   = require('bluebird');
var dateFormat = require('dateformat');

// Local modules
var helper = require('./misc');

var changelog = module.exports = {
  needles: [
    '## Upcoming',
    '## Unreleased'
  ],

  update: function (args) {
    return Bluebird.resolve().then(function () {
      if (changelog.exists() && changelog.needsUpdate()) {
        changelog.setVersion(args.version);
        return changelog.commitVersion(args.version);
      }
    });
  },

  changelogPath: function () {
    return path.resolve(process.env.CHANGELOG_HOME || process.cwd(), 'CHANGELOG.md');
  },

  exists: function () {
    return fs.existsSync(this.changelogPath());
  },

  needsUpdate: function () {
    var changelog = this.read();

    return this.needles.some(function (needle) {
      return changelog.indexOf(needle) > -1;
    });
  },

  setVersion: function (version) {
    var content       = this.read();
    var date          = date;
    var formattedDate = dateFormat(date, 'yyyy-mm-dd');
    var replacement   = '## v' + version + ' - ' + formattedDate;

    this.needles.forEach(function (needle) {
      content = content.replace(needle, replacement);
    });

    this.write(content);
  },

  read: function () {
    return fs.readFileSync(this.changelogPath()).toString();
  },

  write: function (newContent) {
    fs.writeFileSync(this.changelogPath(), newContent);
  },

  commitVersion: function (version) {
    return helper.exec('git add CHANGELOG.md').then(function () {
      return helper.exec('git commit -m "Add changes in version: v' + version + '"');
    });
  }
};
