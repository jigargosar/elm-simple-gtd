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
const child_process_1 = require("child_process");
const fs = require("fs");
const logging = require("plylog");
const findup = require("findup-sync");
const YeomanEnvironment = require("yeoman-environment");
const inquirer_1 = require("inquirer");
const application_1 = require("../init/application/application");
const element_1 = require("../init/element/element");
const github_1 = require("../init/github");
const logger = logging.getLogger('init');
const localGenerators = {
    'polymer-1-element': {
        id: 'polymer-init-polymer-1-element:app',
        description: 'A simple Polymer 1.0 element template',
        generator: element_1.createElementGenerator('polymer-1.x'),
    },
    'polymer-2-element': {
        id: 'polymer-init-polymer-2-element:app',
        description: 'A simple Polymer 2.0 element template',
        generator: element_1.createElementGenerator('polymer-2.x'),
    },
    'polymer-1-application': {
        id: 'polymer-init-polymer-1-application:app',
        description: 'A simple Polymer 1.0 application template',
        generator: application_1.createApplicationGenerator('polymer-1.x'),
    },
    'polymer-2-application': {
        id: 'polymer-init-polymer-2-application:app',
        description: 'A simple Polymer 2.0 application',
        generator: application_1.createApplicationGenerator('polymer-2.x'),
    },
    'polymer-1-starter-kit': {
        id: 'polymer-init-polymer-1-starter-kit:app',
        description: 'A Polymer 1.x starter application template, with navigation and "PRPL pattern" loading',
        generator: github_1.createGithubGenerator({
            owner: 'PolymerElements',
            repo: 'polymer-starter-kit',
            semverRange: '^2.0.0',
        }),
    },
    'polymer-2-starter-kit': {
        id: 'polymer-init-polymer-2-starter-kit:app',
        description: 'A Polymer 2.x starter application template, with navigation and "PRPL pattern" loading',
        generator: github_1.createGithubGenerator({
            owner: 'PolymerElements',
            repo: 'polymer-starter-kit',
            semverRange: '^3.0.0',
        }),
    },
    // TODO: Add Shop "^3.0.0" generator once Polymer 2.0 PSK template is
    // released.
    'shop': {
        id: 'polymer-init-shop:app',
        description: 'The "Shop" Progressive Web App demo',
        generator: github_1.createGithubGenerator({
            owner: 'Polymer',
            repo: 'shop',
            semverRange: '^1.0.0',
        }),
    },
};
/**
 * Check if the current shell environment is MinGW. MinGW can't handle some
 * yeoman features, so we can use this check to downgrade gracefully.
 */
function checkIsMinGW() {
    const isWindows = /^win/.test(process.platform);
    if (!isWindows) {
        return false;
    }
    // uname might not exist if using cmd or powershell,
    // which would throw an exception
    try {
        const uname = child_process_1.execSync('uname -s').toString();
        return !!/^mingw/i.test(uname);
    }
    catch (error) {
        logger.debug('`uname -s` failed to execute correctly', { err: error.message });
        return false;
    }
}
/**
 * Get a description for the given generator. If this is an external generator,
 * read the description from its package.json.
 */
function getGeneratorDescription(generator, generatorName) {
    const meta = getGeneratorMeta(generator.resolved, generatorName, '');
    const displayName = getDisplayName(meta.name);
    let description = meta.description;
    if (localGenerators.hasOwnProperty(displayName)) {
        description = localGenerators[displayName].description;
    }
    // If a description exists, format it properly for the command-line
    if (description.length > 0) {
        description = chalk.dim(` - ${description}`);
    }
    return {
        name: `${displayName}${description}`,
        value: generatorName,
        // inquirer is broken and doesn't print descriptions :(
        // keeping this so things work when it does
        short: displayName,
    };
}
/**
 * Get the metadata of a generator from its package.json
 */
function getGeneratorMeta(rootDir, defaultName, defaultDescription) {
    let name = defaultName;
    let description = defaultDescription;
    if (rootDir && rootDir !== 'unknown') {
        try {
            const metapath = findup('package.json', { cwd: rootDir });
            const meta = JSON.parse(fs.readFileSync(metapath, 'utf8'));
            description = meta.description || description;
            name = meta.name || name;
        }
        catch (error) {
            if (error.message === 'not found') {
                logger.debug('no package.json found for generator');
            }
            else {
                logger.debug('unable to read/parse package.json for generator', {
                    generator: defaultName,
                    err: error.message,
                });
            }
        }
    }
    return { name, description };
}
/**
 * Extract the meaningful name from the full Yeoman generator name.
 * Strip the standard generator prefixes ("generator-" and "polymer-init-"),
 * and extract the remainder of the name (the first part of the string before
 * any colons).
 *
 * Examples:
 *
 *   'generator-polymer-init-foo'         === 'foo'
 *   'polymer-init-foo'                   === 'foo'
 *   'foo-bar'                            === 'foo-bar'
 *   'generator-polymer-init-foo:aaa'     === 'foo'
 *   'polymer-init-foo:bbb'               === 'foo'
 *   'foo-bar:ccc'                        === 'foo-bar'
 */
function getDisplayName(generatorName) {
    // Breakdown of regular expression to extract name (group 3 in pattern):
    //
    // Pattern                 | Meaning
    // -------------------------------------------------------------------
    // (generator-)?           | Grp 1; Match "generator-"; Optional
    // (polymer-init)?         | Grp 2; Match "polymer-init-"; Optional
    // ([^:]+)                 | Grp 3; Match one or more characters != ":"
    // (:.*)?                  | Grp 4; Match ":" followed by anything; Optional
    return generatorName.replace(/(generator-)?(polymer-init-)?([^:]+)(:.*)?/g, '$3');
}
/**
 * Create & populate a Yeoman environment.
 */
function createYeomanEnvironment() {
    return __awaiter(this, void 0, void 0, function* () {
        const env = new YeomanEnvironment();
        Object.keys(localGenerators).forEach((generatorName) => {
            const generatorInfo = localGenerators[generatorName];
            env.registerStub(generatorInfo.generator, generatorInfo.id);
        });
        yield new Promise((resolve, reject) => {
            env.lookup((error) => error ? reject(error) : resolve());
        });
        return env;
    });
}
/**
 * Create the prompt used for selecting which template to run. Generate
 * the list of available generators by filtering relevent ones out from
 * the environment list.
 */
function createSelectPrompt(env) {
    const generators = env.getGeneratorsMeta();
    const allGeneratorNames = Object.keys(generators).filter((k) => {
        return k.startsWith('polymer-init') && k !== 'polymer-init:app';
    });
    const choices = allGeneratorNames.map((generatorName) => {
        const generator = generators[generatorName];
        return getGeneratorDescription(generator, generatorName);
    });
    // Some windows emulators (mingw) don't handle arrows correctly
    // https://github.com/SBoudrias/Inquirer.js/issues/266
    // Fall back to rawlist and use number input
    // Credit to
    // https://gist.github.com/geddski/c42feb364f3c671d22b6390d82b8af8f
    const isMinGW = checkIsMinGW();
    return {
        type: isMinGW ? 'rawlist' : 'list',
        name: 'generatorName',
        message: 'Which starter template would you like to use?',
        choices: choices,
    };
}
/**
 * Run the given generator. If no Yeoman environment is provided, a new one
 * will be created. If the generator does not exist in the environment, an
 * error will be thrown.
 */
function runGenerator(generatorName, options) {
    return __awaiter(this, void 0, void 0, function* () {
        options = options || {};
        const templateName = options['templateName'] || generatorName;
        const env = yield (options['env'] || createYeomanEnvironment());
        logger.info(`Running template ${templateName}...`);
        logger.debug(`Running generator ${generatorName}...`);
        const generators = env.getGeneratorsMeta();
        const generator = generators[generatorName];
        if (!generator) {
            logger.error(`Template ${templateName} not found`);
            throw new Error(`Template ${templateName} not found`);
        }
        return new Promise((resolve, reject) => {
            env.run(generatorName, {}, (error) => {
                if (error) {
                    reject(error);
                    return;
                }
                resolve();
            });
        });
    });
}
exports.runGenerator = runGenerator;
/**
 * Prompt the user to select a generator. When the user
 * selects a generator, run it.
 */
function promptGeneratorSelection(options) {
    return __awaiter(this, void 0, void 0, function* () {
        options = options || {};
        const env = yield (options['env'] || createYeomanEnvironment());
        // TODO(justinfagnani): the typings for inquirer appear wrong
        const answers = yield inquirer_1.prompt([createSelectPrompt(env)]);
        const generatorName = answers['generatorName'];
        yield runGenerator(generatorName, { templateName: getDisplayName(generatorName), env: env });
    });
}
exports.promptGeneratorSelection = promptGeneratorSelection;
