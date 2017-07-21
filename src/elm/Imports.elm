port module Imports exposing (..)

import Return exposing (return, singleton)
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
    = NOOP


init =
    singleton ()


update msg model =
    singleton model


subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
