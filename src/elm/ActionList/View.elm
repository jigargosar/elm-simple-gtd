module ActionList.View exposing (..)

import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.FullBleedCapture
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickPreventDefault, onClickStopPropagation)


init appModel model =
    div
        [ class "fullbleed-capture dark"
        , onClick Model.OnDeactivateEditingMode
        ]
        [ div [ class "modal open modal-center", onClickStopPropagation Model.noop ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field" ]
                    [ input [ autofocus True ] [ text "" ]
                    , label [ class "active" ] [ text "Enter action or option name" ]
                    ]
                ]
            ]
        ]
