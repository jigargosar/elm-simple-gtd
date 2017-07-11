module LaunchBar.View exposing (..)

import GroupDoc
import LaunchBar.Messages exposing (LBMsg(..))
import LaunchBar.Models exposing (LBEntity(LBContext), LaunchBar, SearchItem, getName)
import Msg
import X.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Keyboard.Extra as Key exposing (Key(..))
import Model
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import Model
import Stores


init model =
    let
        matchingEntity =
            model.searchResults
                |> List.head
                ?|> Tuple.first
                ?= LaunchBar.Models.defaultEntity

        matchingEntityName =
            matchingEntity |> LaunchBar.Models.getName

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
                , onInput (OnLBInputChanged model >> Msg.OnLaunchBarMsg)
                ]
                [ div [ class "flex-auto ellipsis" ] [ text matchingEntityName ]
                , div [ class "no-wrap input typing" ] [ text model.input ]
                , input
                    [ id "hidden-input"
                    , class "auto-focus"
                    , autofocus True
                    , value model.input
                    ]
                    []
                ]
            ]
