/* global describe, it, beforeEach, afterEach */
'use strict';

// Core modules
var fs = require('fs');

// 3rd party modules
var Bluebird = require('bluebird');
var expect = require('expect.js');
var sinon = require('sinon');

// Local modules
var Support = require('../../lib/support');

describe('Support', function () {
  beforeEach(function () {
    process.env.CHANGELOG_HOME = '/tmp';

    if (fs.existsSync('/tmp/CHANGELOG.md')) {
      fs.unlinkSync('/tmp/CHANGELOG.md');
    }
  });

  afterEach(function () {
    delete process.env.CHANGELOG_HOME;
  });

  describe('misc', function () {
    beforeEach(function () {
      this.helper = Support.misc;
    });

    describe('parseArgs', function () {
      beforeEach(function () {
        this.stub = sinon.stub(Support.misc, 'getCurrentVersion', function () {
          return '2.3.4';
        });
      });

      afterEach(function () {
        this.stub.restore();
      });

      it('returns the first arg as version', function () {
        var args   = { _: ['1.2.3'] };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '1.2.3' });
      });

      it('correctly determines the next bugfix version', function () {
        var args   = { bugfix: true };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '2.3.5' });
      });

      it('correctly treats patch as bugfix', function () {
        var args   = { patch: true };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '2.3.5' });
      });

      it('correctly determines the next minor version', function () {
        var args   = { minor: true };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '2.4.0' });
      });

      it('correctly determines the next major version', function () {
        var args   = { major: true };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '3.0.0' });
      });

      it('accepts semver keywords as versions', function () {
        var args   = { _: ['minor'] };
        var parsed = this.helper.parseArgs(args);

        expect(parsed).to.eql({ version: '2.4.0' });
      });
    });

    describe('validateVersion', function () {
      it('allows a proper version', function () {
        expect(function () {
          this.helper.validateVersion({ version: '9.9.9' });
        }.bind(this)).to.not.throwError();
      });

      it('throws if the version is no version', function () {
        expect(function () {
          this.helper.validateVersion({ version: 'nomnom' });
        }.bind(this)).to.throwError(/Specified version is not valid: nomnom/);
      });

      it('throws if the first CLI argument is no version', function () {
        expect(function () {
          this.helper.validateVersion({ _: ['nomnom'] });
        }.bind(this)).to.throwError(/Specified version is not valid: nomnom/);
      });

      it('throws if the version is too old', function () {
        expect(function () {
          this.helper.validateVersion({ version: '1.1.1' });
        }.bind(this)).to.throwError(/Specified version is smaller than the current one: 1.1.1/);
      });
    });

    describe('exec', function () {
      it('returns a promise', function () {
        expect(this.helper.exec('ls')).to.be.a(Bluebird);
      });

      it('can succeed', function () {
        return this.helper.exec('ls').then(function (result) {
          expect(result).to.be.an(Array);
        });
      });

      it('can fail', function () {
        return this.helper.exec('ls|grep -v grep|grep xxx').catch(function (err) {
          expect(err).to.be.an(Error);
        });
      });
    });
  });
});
