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
class LintCommand {
    constructor() {
        // TODO(rictic): rename to 'lint' here and elsewhere, delete
        // legacy-lint.ts. Also update the README.
        this.name = 'lint';
        this.description = 'Identifies potential errors in your code.';
        this.args = [
            {
                name: 'input',
                type: String,
                alias: 'i',
                defaultOption: true,
                multiple: true,
                description: 'Files to lint. If given, these files will be the only ' +
                    'ones linted, otherwise all files in the project will be linted.'
            },
            {
                name: 'rules',
                type: String,
                alias: 'r',
                multiple: true,
                description: 'The lint rules/rule collections to apply. ' +
                    'See `polymer help lint` for a list of rules.',
            }
        ];
    }
    /**
     * TODO(rictic): things to make configurable:
     *   - lint warning verbosity
     *   - whether to use color (also: can we autodetect if color is supported?)
     *   - add option for input files to polymer.json
     *   - modules to load that can register new rules
     *   - --watch
     *   - --fix
     */
    run(options, config) {
        return __awaiter(this, void 0, void 0, function* () {
            this._loadPlugins(config);
            // Defer dependency loading until this specific command is run.
            const lintImplementation = require('../lint/lint');
            return lintImplementation.lint(options, config);
        });
    }
    extraUsageGroups(config) {
        const lintLib = require('polymer-linter');
        const chalk = require('chalk');
        this._loadPlugins(config);
        const collectionsDocs = [];
        for (const collection of lintLib.registry.allRuleCollections) {
            collectionsDocs.push(`  ${chalk.bold(collection.code)}: ${this._indent(collection.description)}`);
        }
        const rulesDocs = [];
        for (const rule of lintLib.registry.allRules) {
            rulesDocs.push(`  ${chalk.bold(rule.code)}: ${this._indent(rule.description)}`);
        }
        return [
            {
                header: 'Lint Rule Collections',
                content: collectionsDocs.join('\n\n'),
                raw: true
            },
            { header: 'Lint Rules', content: rulesDocs.join('\n\n'), raw: true }
        ];
    }
    _indent(description) {
        return description.split('\n')
            .map((line, idx) => {
            if (idx === 0) {
                return line;
            }
            if (line.length === 0) {
                return line;
            }
            return '      ' + line;
        })
            .join('\n');
    }
    _loadPlugins(_config) {
        // TODO(rictic): implement.
    }
}
exports.LintCommand = LintCommand;
