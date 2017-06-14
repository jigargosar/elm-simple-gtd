module LaunchBar.View exposing (..)

import Context
import ExclusiveMode
import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Fuzzy
import Keyboard.Extra as Key exposing (Key(..))
import LaunchBar
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
import Model exposing (commonMsg)
import Project
import String.Extra as String


init form m =
    let
        fuzzyResults =
            LaunchBar.getFuzzyResults form.input (Model.getActiveContexts m) (Model.getActiveProjects m)

        matchingEntity =
            fuzzyResults
                |> List.head
                ?|> Tuple.first
                ?= LaunchBar.defaultEntity

        matchingEntityName =
            matchingEntity |> LaunchBar.getName

        keyHandler { key } =
            case key of
                Key.Enter ->
                    matchingEntity |> LaunchBar.OnEnter |> Model.OnLaunchBarMsg

                _ ->
                    commonMsg.noOp
    in
        div
            [ class "fullbleed-capture"
            , onKeyDownStopPropagation (keyHandler)
            , onClickStopPropagation Model.OnDeactivateEditingMode
            ]
            [ div
                [ id "launch-bar-container"
                , class "layout horizontal"
                , attribute "onclick"
                    "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
                , onInput (LaunchBar.OnInputChanged form >> Model.OnLaunchBarMsg)
                ]
                [ div [ class "flex-auto ellipsis" ] [ text matchingEntityName ]
                , div [ class "no-wrap input typing" ] [ text form.input ]
                , input
                    [ id "hidden-input"
                    , class "auto-focus"
                    , autofocus True
                    , value form.input
                    ]
                    []
                ]
            ]
