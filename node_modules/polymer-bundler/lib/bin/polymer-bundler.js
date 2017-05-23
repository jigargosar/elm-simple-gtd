#!/usr/bin/env node
"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const commandLineArgs = require("command-line-args");
const commandLineUsage = require("command-line-usage");
const fs = require("fs");
const parse5 = require("parse5");
const mkdirp = require("mkdirp");
const pathLib = require("path");
const bundler_1 = require("../bundler");
const bundle_manifest_1 = require("../bundle-manifest");
console.warn('polymer-bundler is currently in alpha! Use at your own risk!');
const pathArgument = '[underline]{path}';
const optionDefinitions = [
    { name: 'help', type: Boolean, alias: 'h', description: 'Print this message' },
    {
        name: 'version',
        type: Boolean,
        alias: 'v',
        description: 'Print version number'
    },
    {
        name: 'exclude',
        type: String,
        multiple: true,
        description: 'URL to exclude from inlining. Use multiple times to exclude multiple files and folders. HTML tags referencing excluded URLs are preserved.'
    },
    {
        name: 'strip-comments',
        type: Boolean,
        description: 'Strips all HTML comments not containing an @license from the document'
    },
    {
        name: 'inline-scripts',
        type: Boolean,
        description: 'Inline external scripts'
    },
    {
        name: 'inline-css',
        type: Boolean,
        description: 'Inline external stylesheets'
    },
    {
        name: 'out-html',
        type: String,
        description: `If specified, output will be written to ${pathArgument}` +
            ' instead of stdout.',
        typeLabel: `${pathArgument}`
    },
    {
        name: 'manifest-out',
        type: String,
        description: `If specified, the bundle manifest will be written to` +
            `${pathArgument}`,
        typeLabel: `${pathArgument}`
    },
    {
        name: 'shell',
        type: String,
        description: `If specified, shared dependencies will be inlined into` +
            `${pathArgument}`,
        typeLabel: `${pathArgument}`,
    },
    {
        name: 'out-dir',
        type: String,
        description: 'If specified, all output files will be written to ' +
            `${pathArgument}.`,
        typeLabel: `${pathArgument}`
    },
    {
        name: 'in-html',
        type: String,
        defaultOption: true,
        multiple: true,
        description: 'Input HTML. If not specified, will be the last command line argument.'
    },
    {
        name: 'sourcemaps',
        type: Boolean,
        defaultOption: false,
        description: 'Create and process sourcemaps for scripts.'
    }
];
const usage = [
    { header: 'Usage', content: ['polymer-bundler [options...] <in-html>'] },
    { header: 'Options', optionList: optionDefinitions },
    {
        header: 'Examples',
        content: [
            {
                desc: 'Inline the HTML Imports of \`target.html\` and print the resulting HTML to standard output.',
                example: 'polymer-bundler target.html'
            },
            {
                desc: 'Inline the HTML Imports of \`target.html\`, treat \`path/to/target/\` as the webroot of target.html, and make all urls absolute to the provided webroot.',
                example: 'polymer-bundler -p "path/to/target/" /target.html'
            },
            {
                desc: 'Inline the HTML Imports of \`target.html\` that are not in the directory \`path/to/target/subpath\` nor \`path/to/target/subpath2\`.',
                example: 'polymer-bundler --exclude "path/to/target/subpath/" --exclude "path/to/target/subpath2/" target.html'
            },
            {
                desc: 'Inline scripts in \`target.html\` as well as HTML Imports. Exclude flags will apply to both Imports and Scripts.',
                example: 'polymer-bundler --inline-scripts target.html'
            },
        ]
    },
];
const options = commandLineArgs(optionDefinitions);
const entrypoints = options['in-html'];
function printHelp() {
    console.log(commandLineUsage(usage));
}
const pkg = require('../../package.json');
function printVersion() {
    console.log('polymer-bundler:', pkg.version);
}
if (options.version) {
    printVersion();
    process.exit(0);
}
if (options.help || !entrypoints) {
    printHelp();
    process.exit(0);
}
options.excludes = options.exclude || [];
options.stripComments = options['strip-comments'];
options.implicitStrip = !options['no-implicit-strip'];
options.inlineScripts = options['inline-scripts'];
options.inlineCss = options['inline-css'];
if (options.shell) {
    options.strategy = bundle_manifest_1.generateShellMergeStrategy(options.shell, 2);
}
function documentCollectionToManifestJson(documents) {
    const manifest = {};
    for (const document of documents) {
        const url = document[0];
        const files = document[1].files;
        manifest[url] = Array.from(files);
    }
    return manifest;
}
(() => __awaiter(this, void 0, void 0, function* () {
    const bundler = new bundler_1.Bundler(options);
    let bundles;
    try {
        const shell = options.shell;
        if (shell) {
            if (entrypoints.indexOf(shell) === -1) {
                throw new Error('Shell must be provided as `in-html`');
            }
        }
        const manifest = yield bundler.generateManifest(entrypoints);
        const result = yield bundler.bundle(manifest);
        bundles = result.documents;
    }
    catch (err) {
        console.log(err);
        return;
    }
    if (bundles.size > 1) {
        const outDir = options['out-dir'];
        if (!outDir) {
            throw new Error('Must specify out-dir when bundling multiple entrypoints');
        }
        for (const bundle of bundles) {
            const url = bundle[0];
            const ast = bundle[1].ast;
            const out = pathLib.join(process.cwd(), outDir, url);
            const finalDir = pathLib.dirname(out);
            mkdirp.sync(finalDir);
            const serialized = parse5.serialize(ast);
            const fd = fs.openSync(out, 'w');
            fs.writeSync(fd, serialized + '\n');
            fs.closeSync(fd);
        }
        if (options['manifest-out']) {
            const manifestJson = documentCollectionToManifestJson(bundles);
            const fd = fs.openSync(options['manifest-out'], 'w');
            fs.writeSync(fd, JSON.stringify(manifestJson));
            fs.closeSync(fd);
        }
        return;
    }
    const doc = bundles.get(entrypoints[0]);
    if (!doc) {
        return;
    }
    const serialized = parse5.serialize(doc.ast);
    if (options['out-html']) {
        const fd = fs.openSync(options['out-html'], 'w');
        fs.writeSync(fd, serialized + '\n');
        fs.closeSync(fd);
    }
    else {
        process.stdout.write(serialized);
    }
}))().catch((err) => {
    console.log(err.stack);
    process.stderr.write(require('util').inspect(err));
    process.exit(1);
});
//# sourceMappingURL=polymer-bundler.js.map