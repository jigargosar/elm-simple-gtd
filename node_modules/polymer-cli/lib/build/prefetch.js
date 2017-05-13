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
Object.defineProperty(exports, "__esModule", { value: true });
const dom5 = require("dom5");
const parse5 = require("parse5");
const path = require("path");
const logging = require("plylog");
const path_transformers_1 = require("polymer-build/lib/path-transformers");
const stream_1 = require("stream");
const logger = logging.getLogger('cli.build.prefech');
class PrefetchTransform extends stream_1.Transform {
    constructor(project) {
        super({ objectMode: true });
        this.config = project.config;
        this.analyzer = project.analyzer;
        this.fileMap = new Map();
    }
    pullUpDeps(file, deps, rel) {
        const contents = file.contents.toString();
        const url = path_transformers_1.urlFromPath(this.config.root, file.path);
        const updated = createLinks(contents, url, deps, rel);
        file.contents = new Buffer(updated);
    }
    _transform(file, _encoding, callback) {
        if (this.isImportantFile(file)) {
            // hold on to the file for safe keeping
            this.fileMap.set(file.path, file);
            callback(null);
        }
        else {
            callback(null, file);
        }
    }
    isImportantFile(file) {
        return file.path === this.config.entrypoint ||
            this.config.allFragments.indexOf(file.path) > -1;
    }
    _flush(done) {
        if (this.fileMap.size === 0) {
            return done();
        }
        this.analyzer.analyzeDependencies.then((depsIndex) => {
            const fragmentToDeps = new Map(depsIndex.fragmentToDeps);
            if (this.config.entrypoint && this.config.shell) {
                const file = this.fileMap.get(this.config.entrypoint);
                if (file == null)
                    throw new TypeError('file is null');
                // forward shell's dependencies to main to be prefetched
                const deps = fragmentToDeps.get(this.config.shell);
                if (deps) {
                    this.pullUpDeps(file, deps, 'prefetch');
                }
                this.push(file);
                this.fileMap.delete(this.config.entrypoint);
            }
            for (const importUrl of this.config.allFragments) {
                const file = this.fileMap.get(importUrl);
                if (file == null)
                    throw new TypeError('file is null');
                const deps = fragmentToDeps.get(importUrl);
                if (deps) {
                    this.pullUpDeps(file, deps, 'import');
                }
                this.push(file);
                this.fileMap.delete(importUrl);
            }
            for (const leftover of this.fileMap.keys()) {
                logger.warn('File was listed in fragments but not found in stream:', leftover);
                this.push(this.fileMap.get(leftover));
                this.fileMap.delete(leftover);
            }
            done();
        });
    }
}
exports.PrefetchTransform = PrefetchTransform;
/**
 * Returns the given HTML updated with import or prefetch links for the given
 * dependencies. The given url and deps are expected to be project-relative
 * URLs (e.g. "index.html" or "src/view.html").
 *
 * When rel is prefetch, we assume we have the top-level entry point (which can
 * be served from any URL), and output absolute URLs. Otherwise we output
 * relative URLs.
 */
function createLinks(html, url, deps, rel) {
    const ast = parse5.parse(html);
    // parse5 always produces a <head> element.
    const head = dom5.query(ast, dom5.predicates.hasTagName('head'));
    for (const dep of deps) {
        let href;
        if (rel === 'prefetch') {
            href = '/' + dep;
        }
        else {
            href = path.posix.relative(path.posix.dirname(url), dep);
        }
        const link = dom5.constructors.element('link');
        dom5.setAttribute(link, 'rel', rel);
        dom5.setAttribute(link, 'href', href);
        dom5.append(head, link);
    }
    return parse5.serialize(ast);
}
exports.createLinks = createLinks;
