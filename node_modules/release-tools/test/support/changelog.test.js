/* global describe, it, beforeEach, afterEach */
'use strict';

// Core modules
var fs = require('fs');
var path = require('path');

// 3rd party modules
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

  describe('changelog', function () {
    beforeEach(function () {
      this.helper = Support.changelog;
    });

    describe('update', function () {
      beforeEach(function () {
        this.mock = sinon.mock(this.helper);
      });

      afterEach(function () {
        this.mock.verify();
      });

      it('does not modify the changelog if there is none', function () {
        this.mock.expects('setVersion').never();
        return this.helper.update({ version: '1.2.3' });
      });

      it('does not modify the changelog if there is no needle in the changelog', function () {
        fs.writeFileSync('/tmp/CHANGELOG.md', 'nomnom');
        this.mock.expects('setVersion').never();
        return this.helper.update({ version: '1.2.3' });
      });

      Support.changelog.needles.forEach(function (needle) {
        describe('with the needle "' + needle + '"', function () {
          it('inserts the version number if the needle is in the changelog', function () {
            fs.writeFileSync('/tmp/CHANGELOG.md', needle);
            this.mock.expects('setVersion').once().withArgs('1.2.3');
            this.mock.expects('commitVersion').once().withArgs('1.2.3');
            return this.helper.update({ version: '1.2.3' });
          });
        });
      });
    });

    describe('changelogPath', function () {
      it('uses the process path by default', function () {
        delete process.env.CHANGELOG_HOME;
        expect(this.helper.changelogPath()).to.equal(
          path.resolve(__dirname, '..', '..', 'CHANGELOG.md')
        );
      });

      it('uses the CHANGELOG_HOME if specified', function () {
        expect(this.helper.changelogPath()).to.equal('/tmp/CHANGELOG.md');
      });
    });

    describe('exists', function () {
      it('returns false if there is no changelog file', function () {
        expect(this.helper.exists()).to.be(false);
      });

      it('returns true if there is a changelog file', function () {
        fs.writeFileSync('/tmp/CHANGELOG.md', 'nomnom');
        expect(this.helper.exists()).to.be(true);
      });
    });

    describe('needsUpdate', function () {
      it('returns false if the changelog does not contain the expected needle', function () {
        fs.writeFileSync('/tmp/CHANGELOG.md', 'nomnom');
        expect(this.helper.needsUpdate()).to.be(false);
      });

      Support.changelog.needles.forEach(function (needle) {
        describe('with the needle "' + needle + '"', function () {
          it('returns true if the change log contains the expected needle', function () {
            fs.writeFileSync('/tmp/CHANGELOG.md', needle);
            expect(this.helper.needsUpdate()).to.be(true);
          });
        });
      });
    });

    describe('setVersion', function () {
      Support.changelog.needles.forEach(function (needle) {
        describe('with the needle "' + needle + '"', function () {
          beforeEach(function () {
            fs.writeFileSync('/tmp/CHANGELOG.md', needle);
          });

          it('replaces the needle', function () {
            expect(this.helper.read()).to.contain(needle);
            this.helper.setVersion('1.2.3');
            expect(this.helper.read()).to.not.contain(needle);
          });

          it('sets the version', function () {
            this.helper.setVersion('1.2.3');
            expect(this.helper.read()).to.contain('## v1.2.3 - ');
          });

          it('sets the date', function () {
            var clock = sinon.useFakeTimers();
            this.helper.setVersion('1.2.3');
            expect(this.helper.read()).to.contain(' - 1970-01-01');
            clock.restore();
          });
        });
      });
    });
  });
});
