/* global describe, it, beforeEach, afterEach */
'use strict';

// 3rd party modules
var expect = require('expect.js');
var sinon = require('sinon');

// Local modules
var index = require('../lib/index');
var Support = require('../lib/support');

describe('index', function () {
  beforeEach(function () {
    this.mock = sinon.mock(Support);
  });

  afterEach(function () {
    this.mock.verify();
  });

  it('exports the npm module', function () {
    expect(index.npm).to.be.an('object');
  });
});
