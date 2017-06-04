module LaunchBar.View exposing (..)

import EditMode
import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg exposing (commonMsg)


init m =
    case Model.getEditMode m of
        EditMode.LaunchBar form ->
            formView form m

        _ ->
            span [] []


formView form m =
    div
        [ id "modal-background"
        , onKeyDownStopPropagation (\_ -> commonMsg.noOp)
        , onClickStopPropagation Msg.DeactivateEditingMode
        ]
        [ div
            [ id "launch-bar-container"
            , attribute "onclick"
                "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
            , onInput (Msg.UpdateLaunchBarInput form)
            ]
            [ div [] [ text "Input:", text form.input ]
            , input
                [ id "hidden-input"
                , class "auto-focus"
                , autofocus True
                , value form.input
                ]
                []
            ]
        ]
