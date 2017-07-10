module View.FullBleedCapture exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


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
