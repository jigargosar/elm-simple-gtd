module LaunchBar.View exposing (..)

import Msg
import X.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Keyboard.Extra as Key exposing (Key(..))
import LaunchBar
import Model
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import Model


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
                    matchingEntity |> LaunchBar.OnLBEnter |> Msg.OnLaunchBarMsg

                _ ->
                    Model.noop
    in
        div
            [ class "overlay"
            , onKeyDownStopPropagation (keyHandler)
            , onClickStopPropagation Msg.OnDeactivateEditingMode
            ]
            [ div
                [ id "launch-bar-container"
                , class "layout horizontal"
                , attribute "onclick"
                    "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
                , onInput (LaunchBar.OnLBInputChanged form >> Msg.OnLaunchBarMsg)
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
