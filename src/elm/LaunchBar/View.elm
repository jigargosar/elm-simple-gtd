module LaunchBar.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Keyboard.Extra as Key exposing (Key(..))
import LaunchBar.Models exposing (..)
import Overlays.LaunchBar exposing (LaunchBarMsg(..))
import Toolkit.Operators exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)


init model =
    let
        matchingEntity =
            model.searchResults
                |> List.head
                ?|> Tuple.first
                ?= LaunchBar.Models.defaultEntity

        matchingEntityName =
            matchingEntity |> LaunchBar.Models.getSearchItemName

        keyHandler { key } =
            case key of
                Key.Enter ->
                    matchingEntity |> OnLBEnter

                _ ->
                    NOOP
    in
    div
        [ class "overlay"
        , onKeyDownStopPropagation keyHandler
        , onClickStopPropagation OnCancel
        ]
        [ div
            [ id "launch-bar-container"
            , class "layout horizontal"
            , attribute "onclick"
                "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
            , onInput (OnLBInputChanged model)
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
