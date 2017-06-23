module View.FullBleedCapture exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)


type alias ViewModel msg =
    { onMouseDown : msg
    , children : Html msg
    }


init vm =
    div
        [ class "overlay"
        , onMouseDown vm.onMouseDown
        ]
        vm.children
