"use strict";
/**
 * @license
 * Copyright (c) 2016 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at
 * http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at
 * http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at
 * http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at
 * http://polymer.github.io/PATENTS.txt
 */
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs = require("fs");
const path = require("path");
const logging = require("plylog");
const semver = require("semver");
const request = require("request");
const GitHubApi = require("github");
const gunzip = require('gunzip-maybe');
const tar = require('tar-fs');
const logger = logging.getLogger('cli.github');
class GithubResponseError extends Error {
    constructor(statusCode, statusMessage) {
        super('unexpected response: ' + statusCode + ' ' + statusMessage);
        this.name = 'GithubResponseError';
        this.statusCode = statusCode;
        this.statusMessage = statusMessage;
    }
}
exports.GithubResponseError = GithubResponseError;
class Github {
    static tokenFromFile(filename) {
        try {
            return fs.readFileSync(filename, 'utf8').trim();
        }
        catch (error) {
            return null;
        }
    }
    constructor(opts) {
        this._token = opts.githubToken || Github.tokenFromFile('token');
        this._owner = opts.owner;
        this._repo = opts.repo;
        this._github = opts.githubApi || new GitHubApi({
            protocol: 'https',
        });
        if (this._token != null) {
            this._github.authenticate({
                type: 'oauth',
                token: this._token,
            });
        }
        this._request = opts.requestApi || request;
    }
    /**
     * Given a Github tarball URL, download and extract it into the outDir
     * directory.
     */
    extractReleaseTarball(tarballUrl, outDir) {
        return __awaiter(this, void 0, void 0, function* () {
            const tarPipe = tar.extract(outDir, {
                ignore: (_, header) => {
                    const splitPath = path.normalize(header.name).split(path.sep);
                    // ignore the top directory in the tarfile to unpack directly to
                    // the cwd
                    return splitPath.length < 1 || splitPath[1] === '';
                },
                map: (header) => {
                    const splitPath = path.normalize(header.name).split(path.sep);
                    const unprefixed = splitPath.slice(1).join(path.sep).trim();
                    // A ./ prefix is needed to unpack top-level files in the tar,
                    // otherwise they're just not written
                    header.name = path.join('.', unprefixed);
                    return header;
                },
            });
            return new Promise((resolve, reject) => {
                this._request({
                    url: tarballUrl,
                    headers: {
                        'User-Agent': 'request',
                        'Authorization': (this._token) ? `token ${this._token}` :
                            undefined,
                    }
                })
                    .on('response', function (response) {
                    if (response.statusCode !== 200) {
                        reject(new GithubResponseError(response.statusCode, response.statusMessage));
                        return;
                    }
                    logger.info('Unpacking template files');
                })
                    .on('error', reject)
                    .pipe(gunzip())
                    .on('error', reject)
                    .pipe(tarPipe)
                    .on('error', reject)
                    .on('finish', () => {
                    logger.info('Finished writing template files');
                    resolve();
                });
            });
        });
    }
    /**
     * Get all Github releases and match their tag names against the given semver
     * range. Return the release with the latest possible match.
     */
    getSemverRelease(semverRange) {
        return __awaiter(this, void 0, void 0, function* () {
            // Note that we only see the 100 most recent releases. If we ever release
            // enough versions that this becomes a concern, we'll need to improve this
            // call to request multiple pages of results.
            const releases = yield this._github.repos.getReleases({
                owner: this._owner,
                repo: this._repo,
                per_page: 100,
            });
            const validReleaseVersions = releases.filter((r) => semver.valid(r.tag_name)).map((r) => r.tag_name);
            const maxSatisfyingReleaseVersion = semver.maxSatisfying(validReleaseVersions, semverRange);
            const maxSatisfyingRelease = releases.find((r) => r.tag_name === maxSatisfyingReleaseVersion);
            if (!maxSatisfyingRelease) {
                throw new Error(`${this._owner}/${this._repo} has no releases matching ${semverRange}.`);
            }
            return maxSatisfyingRelease;
        });
    }
}
exports.Github = Github;
