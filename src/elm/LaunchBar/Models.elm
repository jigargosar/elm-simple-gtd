module LaunchBar.Models exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import Regex
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)


type LBEntity
    = LBContext ContextDoc
    | LBProject ProjectDoc
    | LBProjects
    | LBContexts


type alias LaunchBar =
    { input : String
    , updatedAt : Time
    }


type alias ModelF =
    LaunchBar -> LaunchBar


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
