module Logger
    exposing
        ( Config
        , ExternalLoggingFunction
        , Level(..)
        , customConfig
        , defaultConfig
        , levelString
        , log
        )

{-| This module provides a generic logger with log levels. Logs will only be
printed if the log level matches or exceeds the minimum log level in the
Configuration.

The package's concept is that some other module in the implementation scope of
the app implements convenience functions wrapping a `Config` and `Level`s into
single functions. See the following template for an example:

    module MyUtils

    import Logger

    loggerConfig : Logger.Config
    loggerConfig =
        Logger.config Logger.Info

    log : String -> a -> a
    log =
        Logger.log loggerConfig Logger.Debug

    logVerbose : String -> a -> a
    logVerbose =
        Logger.log loggerConfig Logger.Verbose


The value `loggerConfig` should be created using `Logger.config` with the
minimum log level. By changing the minimum log level in a central module
you can silence any logs in code that fall below that level. The above template
implementation allows you to replace calls to `Debug.log` with `MyUtils.log`.

## Configuration
@docs Level, Config, defaultConfig, levelString

## Logging
@docs log

## Advanced logging

You can provide a custom `ExternalLoggingFunction` via `customConfig` allowing
you to replace the default configuration that uses `Debug.log` for printing the
messages.

The example implementation prints nicely colored code logs to the browser's
console.

@docs ExternalLoggingFunction, customConfig
-}


{-| Log levels can be used to differentiate between the importance of logs.
Calls to `log` with a lower log level than the `minimumLevel` specified in the
`Config` will be silent.
setting the minimum log level in the Config,
-}
type Level
    = Error
    | Warning
    | Info
    | Debug
    | Verbose


{-| Create a default config with a given minimum log level.
At a later stage we might allow to configure the color scheme and
string representation of the loglevel.
-}
defaultConfig : Level -> Config a
defaultConfig minimumLevel =
    customConfig minimumLevel elmLog


{-| A type of function that takes a log level, message, and a value
to log and prints it to the console. The defaultConfig wrapps
`Debug.log` to achieve this. If you would like to have colored log messages,
have a look at the example implementation.
-}
type alias ExternalLoggingFunction a =
    Level -> String -> a -> a


{-| A configuration that allows you to provide a custom logging function.
-}
customConfig : Level -> ExternalLoggingFunction a -> Config a
customConfig minimumLevel logFunc =
    Config
        { logFunc = logFunc
        , minimumLevel = minimumLevel
        }


{-| Public interface for the configuration to hide the implementation details
of the internal configuration. Use `config` to create a configuration.
-}
type Config a
    = Config (InternalConfig a)


type alias InternalConfig a =
    { logFunc : ExternalLoggingFunction a
    , minimumLevel : Level
    }


{-| Logs the given string and value at the provided log level only if it exceeds
the minimumLevel of the Config. Returns the value provided.
-}
log : Config a -> Level -> String -> a -> a
log config =
    case config of
        Config internalConfig ->
            internalLog internalConfig


internalLog : InternalConfig a -> Level -> String -> a -> a
internalLog config messageLevel message value =
    if toInt messageLevel >= toInt config.minimumLevel then
        config.logFunc messageLevel message value
    else
        value


elmLog : Level -> String -> a -> a
elmLog level message value =
    let
        taggedMessage =
            (levelString level) ++ ": " ++ message
    in
        Debug.log taggedMessage value


{-| A string representation for a log level.
-}
levelString : Level -> String
levelString logLevel =
    case logLevel of
        Error ->
            "Error"

        Warning ->
            "Warning"

        Info ->
            "Info"

        Debug ->
            "Debug"

        Verbose ->
            "Verbose"


toInt : Level -> Int
toInt logLevel =
    case logLevel of
        Error ->
            4

        Warning ->
            3

        Info ->
            2

        Debug ->
            1

        Verbose ->
            0
