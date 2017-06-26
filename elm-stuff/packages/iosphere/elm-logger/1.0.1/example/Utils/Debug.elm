module Utils.Debug
    exposing
        ( log
        , logVerbose
        , logInfo
        , logWarning
        , logError
        )

{-|
This is the template implementation of a logger helper that should reside in the
elm app's code base. It sets the minimum log level and provides convenience
log functions to avoid importing `Logger` at the call sites.
-}

import Logger


-- Only needed when using nativeLog to print logs:

import Native.Logger


nativeLog : Logger.ExternalLoggingFunction a
nativeLog level message value =
    Native.Logger.log (Logger.levelString level) (toColor level) message value


{-| Create the Logger.Config used in this app.
-}
loggerConfig : Logger.Config a
loggerConfig =
    -- To use elm logger:
    -- Logger.defaultConfig Logger.Info
    -- This uses colored console output via native logger
    Logger.customConfig Logger.Info nativeLog



--
{- We provide convenience log functions to avoid knowledge about
   Utils.Logger at the call site.
-}


log : String -> a -> a
log =
    Logger.log loggerConfig Logger.Debug


logVerbose : String -> a -> a
logVerbose =
    Logger.log loggerConfig Logger.Verbose


logInfo : String -> a -> a
logInfo =
    Logger.log loggerConfig Logger.Info


logWarning : String -> a -> a
logWarning =
    Logger.log loggerConfig Logger.Warning


logError : String -> a -> a
logError =
    Logger.log loggerConfig Logger.Error


toColor : Logger.Level -> String
toColor logLevel =
    case logLevel of
        Logger.Error ->
            "red"

        Logger.Warning ->
            "orange"

        Logger.Info ->
            "green"

        Logger.Debug ->
            "purple"

        Logger.Verbose ->
            "LightBlue"
