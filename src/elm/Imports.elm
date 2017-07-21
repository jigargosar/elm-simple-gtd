port module Imports exposing (..)

import Return exposing (command, return, singleton)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


port output : String -> Cmd msg


type alias Model =
    ()


type Msg
    = ParseImports


init =
    singleton ()
        |> update ParseImports


update msg =
    case msg of
        ParseImports ->
            "hw" |> output >> command


subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = (\msg -> singleton >> update msg)
        , subscriptions = subscriptions
        }
