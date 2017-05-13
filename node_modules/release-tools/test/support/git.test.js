/* global describe, it, beforeEach, afterEach */
'use strict';

// 3rd party modules
var expect = require('expect.js');
var sinon = require('sinon');

// Local modules
var git = require('../../lib/support').git;

describe('Support', function () {
  describe('git', function () {
    describe('parseGitCommits', function () {
      it('finds major changes in the subject', function () {
        var commits = ['[major] breaking change<<-->>' ];

        expect(git.parseGitCommits(commits)).to.eql([
          { subject: '[major] breaking change', body: '', changeType: 'major' }
        ]);
      });

      it('finds minor changes in the subject', function () {
        var commits = ['[minor] feature<<-->>' ];

        expect(git.parseGitCommits(commits)).to.eql([
          { subject: '[minor] feature', body: '', changeType: 'minor' }
        ]);
      });

      it('finds minor changes in the subject with feature fragment', function () {
        var commits = ['[feature] feature<<-->>' ];

        expect(git.parseGitCommits(commits)).to.eql([
          { subject: '[feature] feature', body: '', changeType: 'minor' }
        ]);
      });

      it('finds minor changes in the subject', function () {
        var commits = ['[patch] fix<<-->>' ];

        expect(git.parseGitCommits(commits)).to.eql([
          { subject: '[patch] fix', body: '', changeType: 'patch' }
        ]);
      });

      it('splits subject and body', function () {
        var commits = ['subject<<-->>body'];

        expect(git.parseGitCommits(commits)).to.eql([
          { subject: 'subject', body: 'body', changeType: undefined }
        ]);
      });
    });

    describe('detectChangeType', function () {
      it('detects a major change in a list of changes', function () {
        var commits = [
          { subject: 'major change', changeType: 'major' },
          { subject: 'minor change', changeType: 'minor' },
          { subject: 'patch change', changeType: 'patch' }
        ];

        expect(git.detectChangeType(commits)).to.eql({ major: true });
      });

      it('detects a minor change in a list of changes', function () {
        var commits = [
          { subject: 'minor change', changeType: 'minor' },
          { subject: 'patch change', changeType: 'patch' }
        ];

        expect(git.detectChangeType(commits)).to.eql({ minor: true });
      });

      it('detects a major change in a list of changes', function () {
        var commits = [
          { subject: 'patch change', changeType: 'patch' }
        ];

        expect(git.detectChangeType(commits)).to.eql({ patch: true });
      });

      it('throws an error if no change was detected and there is no fallback', function () {
        var commits = [
          { subject: 'some change', changeType: undefined }
        ];

        expect(function () {
          return git.detectChangeType(commits)
        }).to.throwException(/No change type detected/);
      });

      it('respects the fallback if no change was detected', function () {
        var commits = [
          { subject: 'some change', changeType: undefined }
        ];

        expect(git.detectChangeType(commits, 'minor')).to.eql({ minor: true });
      });
    });
  });
});
