module LaunchBar.View exposing (..)

import Context
import EditMode
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
import Msg exposing (commonMsg)
import Project
import String.Extra as String


init m =
    case Model.getEditMode m of
        EditMode.LaunchBar form ->
            formView form m

        _ ->
            span [] []


formView form m =
    let
        entityList =
            let
                contexts =
                    Model.getActiveContexts m
                        .|> LaunchBar.Context

                projects =
                    Model.getActiveProjects m
                        .|> LaunchBar.Project
            in
                projects ++ contexts

        fuzzyResults =
            LaunchBar.getFuzzyResults form.input entityList

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
                    matchingEntity |> LaunchBar.OnEnter |> Msg.OnLaunchBarAction

                _ ->
                    commonMsg.noOp
    in
        div
            [ class "modal-background"
            , onKeyDownStopPropagation (keyHandler)
            , onClickStopPropagation Msg.DeactivateEditingMode
            ]
            [ div
                [ id "launch-bar-container"
                , class "layout horizontal justified"
                , attribute "onclick"
                    "console.log('focusing');document.getElementById('hidden-input').focus(); event.stopPropagation(); event.preventDefault();"
                , onInput (Msg.UpdateLaunchBarInput form)
                ]
                [ div [ class "" ] [ text "", text matchingEntityName ]
                , div [ class "" ] [ text "", text form.input ]
                , input
                    [ id "hidden-input"
                    , class "auto-focus"
                    , autofocus True
                    , value form.input
                    ]
                    []
                ]
            ]
