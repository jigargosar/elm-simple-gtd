module LaunchBar.Form exposing (..)

import Char
import Keyboard.Extra
import Regex
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)


type alias Model =
    { input : String
    , updatedAt : Time
    }


type alias ModelF =
    Model -> Model


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
