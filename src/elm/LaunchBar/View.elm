module LaunchBar.View exposing (..)

import EditMode
import Ext.Keyboard exposing (onKeyDown)
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
import Msg


init m =
    let
        val =
            case Model.getEditMode m of
                EditMode.LaunchBar form ->
                    form.input

                _ ->
                    ""
    in
        div
            [ id "launch-bar-container"
            , attribute "onclick" "console.log('focusing');document.getElementById('hidden-input').focus(); return false;"
            , onInput (Msg.UpdateLaunchBarInput { input = val })
            ]
            [ div [] [ text "Input:", text val ]
            , input [ id "hidden-input", attribute "type" "text" ] []
            ]
