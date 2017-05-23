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
const chalk = require("chalk");
const logging = require("plylog");
const polymer_analyzer_1 = require("polymer-analyzer");
const warning_filter_1 = require("polymer-analyzer/lib/warning/warning-filter");
const warning_printer_1 = require("polymer-analyzer/lib/warning/warning-printer");
const lintLib = require("polymer-linter");
const command_1 = require("../commands/command");
const logger = logging.getLogger('cli.lint');
function lint(options, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const lintOptions = (config.lint || {});
        const ruleCodes = options.rules || lintOptions.rules;
        if (ruleCodes === undefined) {
            logger.warn(`You must state which lint rules to use. You can use --rules, ` +
                `but for a project it's best to use polymer.json. e.g.

{
  "lint": {
    "rules": ["polymer-2"]
  }
}`);
            return new command_1.CommandResult(1);
        }
        const rules = lintLib.registry.getRules(ruleCodes || lintOptions.rules);
        const filter = new warning_filter_1.WarningFilter({
            warningCodesToIgnore: new Set(lintOptions.ignoreWarnings || []),
            minimumSeverity: polymer_analyzer_1.Severity.WARNING
        });
        const analyzer = new polymer_analyzer_1.Analyzer({
            urlLoader: new polymer_analyzer_1.FSUrlLoader(config.root),
            urlResolver: new polymer_analyzer_1.PackageUrlResolver(),
        });
        const linter = new lintLib.Linter(rules, analyzer);
        let warnings;
        if (options.input) {
            warnings = yield linter.lint(options.input);
        }
        else {
            warnings = yield linter.lintPackage();
        }
        const filtered = warnings.filter((w) => !filter.shouldIgnore(w));
        const printer = new warning_printer_1.WarningPrinter(process.stdout, { verbosity: 'full', color: true });
        yield printer.printWarnings(filtered);
        if (filtered.length > 0) {
            let message = '';
            const errors = filtered.filter((w) => w.severity === polymer_analyzer_1.Severity.ERROR);
            const warnings = filtered.filter((w) => w.severity === polymer_analyzer_1.Severity.WARNING);
            const infos = filtered.filter((w) => w.severity === polymer_analyzer_1.Severity.INFO);
            if (errors.length > 0) {
                message += ` ${errors.length} ${chalk.red('errors')}`;
            }
            if (warnings.length > 0) {
                message += ` ${warnings.length} ${chalk.yellow('warnings')}`;
            }
            if (infos.length > 0) {
                message += ` ${infos.length} ${chalk.green('info')} messages`;
            }
            console.log(`\n\nFound ${message}.`);
            return new command_1.CommandResult(1);
        }
    });
}
exports.lint = lint;
