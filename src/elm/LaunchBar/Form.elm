module LaunchBar.Form exposing (..)

import LaunchBar.Types exposing (LaunchBarForm)
import Regex
import Time exposing (Time)


type alias ModelF =
    LaunchBarForm -> LaunchBarForm


create now =
    { input = ""
    , updatedAt = now
    }


updateInput : Time -> String -> ModelF
updateInput now input model =
    let
        newInput =
            input
                |> if now - model.updatedAt > 1 * Time.second then
                    Regex.replace (Regex.AtMost 1)
                        (Regex.regex ("^" ++ Regex.escape model.input))
                        (\_ -> "")
                   else
                    identity
    in
        updateInputHelp newInput model now


updateInputHelp input model now =
    { model | input = input }
        |> (\model -> { model | updatedAt = now })
