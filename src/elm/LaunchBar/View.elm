module LaunchBar.View exposing (..)

import LaunchBar.Types exposing (LBMsg(..))
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
import Stores


init form m =
    let
        fuzzyResults =
            LaunchBar.getFuzzyResults form.input (Stores.getActiveContexts m) (Stores.getActiveProjects m)

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
                    matchingEntity |> OnLBEnter |> Msg.OnLaunchBarMsg

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
                , onInput (OnLBInputChanged form >> Msg.OnLaunchBarMsg)
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
