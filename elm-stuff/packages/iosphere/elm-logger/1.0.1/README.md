# elm-logger

This package provides a generic logger with log levels. Logs will only be
printed if the log level matches or exceeds the minimum log level in the
Configuration.

The package's concept is that some other module in the implementation scope of
the app implements convenience functions wrapping a Config and Levels into
single functions. See the following template for an example:

    module MyUtils

    import Logger

    loggerConfig : Logger.Config
    loggerConfig =
        Logger.defaultConfig Logger.Info

    log : String -> a -> a
    log =
        Logger.log loggerConfig Logger.Debug

    logVerbose : String -> a -> a
    logVerbose =
        Logger.log loggerConfig Logger.Verbose


The value `loggerConfig` should be created using `Logger.defaultConfig` with the
minimum log level. By changing the minimum log level in a central module you can
silence any logs in code that fall below that level. The above template
implementation allows you to replace calls to `Debug.log` with `MyUtils.log`.

Please have a look at the example app.

## Advanced: color coded console logs

You can provide a custom `ExternalLoggingFunction` via `customConfig` allowing
you to replace the default configuration that uses `Debug.log` for printing the
messages.

![Screenshot of a console log using elm-logger](https://github.com/iosphere/elm-logger/raw/1.0.1/console.png)

The example implementation prints nicely colored code logs to the browser's
console.

When using the native example implementation in your project, ensure to update
the name of the native function `_iosphere$elm_logger$Native_Logger`
in [Logger.js](src/example/Native/Logger.js) to match the name of your
organization and app. If you get a runtime error reading something like
`ReferenceError: Can't find variable: _org$appname$Native_Logger`
you will need to update the Logger.js to reference that name.

You will also need to enable native module's for your elm project by including
the following value in your `elm-package.json`:

```json
    "native-modules": true,
```
