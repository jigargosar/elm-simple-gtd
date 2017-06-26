module Main exposing (..)

import Html exposing (Html, text)
import Utils.Debug


main : Html msg
main =
    let
        _ =
            -- Minimum log level is set to Info
            -- This log will not show as Debug log level is below Info
            Utils.Debug.log "Debug" ( 12, 12 )

        _ =
            -- This log will show as Info is minimum log level
            Utils.Debug.logInfo "Record" ({ field = 123 })

        _ =
            -- This log will show as Error is above Info Level
            Utils.Debug.logError "Issue" "Some error message"

        _ =
            -- This log will show as Error is above Info Level
            Utils.Debug.logWarning "Slow network" ( 42, "seconds" )
    in
        text "Open javascript console"
