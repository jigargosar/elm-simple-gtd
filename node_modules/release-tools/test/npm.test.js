/* global describe, it, beforeEach, afterEach */
'use strict';

// 3rd party modules
var sinon = require('sinon');

// Local modules
var npm = require('../lib/npm');
var Support = require('../lib/support');

describe('npm', function () {
  beforeEach(function () {
    this.mocks = {};

    Object.keys(Support).forEach(function (key) {
      this.mocks[key] = sinon.mock(Support[key]);
    }.bind(this));
  });

  afterEach(function () {
    Object.keys(this.mocks).forEach(function (key) {
      this.mocks[key].verify();
    }.bind(this));
  });

  describe('bump', function () {
    it('calls the expected steps', function () {
      this.mocks.changelog.expects('update').once().withArgs({ version: '10.2.3' });
      this.mocks.npm.expects('updatePackage').once().withArgs({ version: '10.2.3' });
      this.mocks.git.expects('push').once().withArgs({ version: '10.2.3' });
      this.mocks.git.expects('pushTags').once().withArgs({ version: '10.2.3' });

      return npm.bump({ version: '10.2.3' });
    });
  });

  describe('release', function () {
    it('calls everything from bump + releases the package', function () {
      this.mocks.changelog.expects('update').once().withArgs({ version: '10.2.3' });
      this.mocks.npm.expects('updatePackage').once().withArgs({ version: '10.2.3' });
      this.mocks.git.expects('push').once().withArgs({ version: '10.2.3' });
      this.mocks.git.expects('pushTags').once().withArgs({ version: '10.2.3' });
      this.mocks.npm.expects('publishPackage').once().withArgs({ version: '10.2.3' });

      return npm.release({ version: '10.2.3' });
    });
  });
});
