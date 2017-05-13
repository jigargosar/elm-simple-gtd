/* global describe, it, beforeEach, afterEach */
'use strict';

// 3rd party modules
var expect = require('expect.js');
var sinon = require('sinon');

var helper = require('./helper');
var bumpAndGetVersion = helper.bumpAndGetVersion;
var callBump = helper.callBump;

describe('npm_bump', function () {
  describe('call without args', function () {
    it('renders the help', function () {
      return bumpAndGetVersion().then(fail, function (err) {
        expect(err.message).to.contain('--bugfix, -b')
      });
    });
  });

  describe('call with bugfix option', function () {
    it('bumps the third fragment', function () {
      return bumpAndGetVersion({ args: '--bugfix' }).then(function (version) {
        expect(version).to.equal('0.0.1');
      });
    });
  });

  describe('call with minor option', function () {
    it('bumps the second fragment', function () {
      return bumpAndGetVersion({ args: '--minor' }).then(function (version) {
        expect(version).to.equal('0.1.0');
      });
    });
  });

  describe('call with major option', function () {
    it('bumps the first fragment', function () {
      return bumpAndGetVersion({ args: '--major' }).then(function (version) {
        expect(version).to.equal('1.0.0');
      });
    });
  });

  describe('call with auto option', function () {
    it('parses the entire history when package version is 0.0.0', function () {
      return bumpAndGetVersion({
        args: '--auto',
        commits: [
          { subject: 'Initial import' },
          { subject: '[minor] Add first feature' }
        ]
      }).then(function (version) {
        expect(version).to.equal('0.1.0');
      });
    });

    it('throws an error if no change type could be found since last tag', function () {
      return bumpAndGetVersion({
        args: '--auto',
        packageVersion: '0.0.1',
        commits: [
          { subject: 'Initial import', tag: 'v0.0.1' },
          { subject: 'Update readme' }
        ]
      }).then(fail, function (err) {
        expect(err.message.trim()).to.contain('No change type detected and no fallback defined!');
      });
    });

    it('falls back to --auto-fallback if no change type was detected', function () {
      return bumpAndGetVersion({
        args: '--auto --auto-fallback patch',
        packageVersion: '0.0.1',
        commits: [
          { subject: 'Initial import', tag: 'v0.0.1' },
          { subject: 'Update readme' }
        ]
      }).then(function (version) {
        expect(version).to.equal('0.0.2');
      });
    });

    it('detects patch level bumps in the body', function () {
      return bumpAndGetVersion({
        args: '--auto --auto-fallback minor',
        commits: [
          { subject: 'Initial import' },
          { subject: 'Update readme', body: '[patch] Some more description' }
        ]
      }).then(function (version) {
        expect(version).to.equal('0.0.1');
      });
    })
  });
});

function fail () {
  expect(1).to.equal(2);
}
