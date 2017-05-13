'use strict';

module.exports = {
  init: function () {
    var yargs = require('yargs');

    yargs = addUsage(yargs);
    yargs = addExamples(yargs);
    yargs = addOptions(yargs);
    yargs = addMisc(yargs);

    return validateCliCall(yargs);
  }
};

function addUsage (args) {
  return args.usage('Usage: $0 [version] [--bugfix|--minor|--major|--auto]');
}

function addExamples (args) {
  return args
    .example('$0 1.2.3', 'Bump version to 1.2.3')
    .example('$0 --bugfix', 'Bump from 1.2.3 to 1.2.4')
    .example('$0 --minor', 'Bump from 1.2.3 to 1.3.0')
    .example('$0 --major', 'Bump from 1.2.3 to 2.0.0')
    .example('$0 --auto', 'Detects change type from git commit messages.');
}

function addOptions (args) {
  return args
    .option('bugfix', {
      demand:   false,
      alias:    'b',
      describe: 'Bump the package to the next bugfix version.',
      boolean: true
    })
    .option('patch', {
      demand:   false,
      alias:    'p',
      describe: 'Bump the package to the next patch version. This is an alias for --bugfix.',
      boolean: true
    })
    .option('minor', {
      demand:   false,
      alias:    'm',
      describe: 'Bump the package to the next minor version.',
      boolean: true
    })
    .option('major', {
      demand:   false,
      alias:    'M',
      describe: 'Bump the package to the next major version.',
      boolean: true
    })
    .option('auto', {
      demand:   false,
      alias:    'a',
      describe: 'Automatically detect which version fragment needs bump.',
      boolean: true
    })
    .option('auto-fallback', {
      demand: false,
      alias: 'f',
      describe: 'Defines version fragment which is bumped in case of failed auto detection.',
      choices: ['major', 'minor', 'patch']
    })
    .option('skip-push', {
      demand: false,
      describe: 'Disables pushes to git remote server.',
      boolean: true
    });
}

function addMisc (args) {
  return args
    .wrap(150)
    .help('help')
    .alias('help', 'h');
}

function validateCliCall (yargs) {
  var argv = yargs.argv;

  function validOptionCount (argv) {
    return [argv.bugfix, argv.patch, argv.minor, argv.major, argv.auto].filter(function (arg) {
      return !!arg;
    }).length === 1;
  }

  if ((argv._.length === 0) && !validOptionCount(argv)) {
    yargs.showHelp();
    process.exit(1);
  } else {
    return argv;
  }
}
