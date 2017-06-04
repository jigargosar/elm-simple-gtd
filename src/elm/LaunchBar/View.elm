module LaunchBar.View exposing (..)

import Context
import EditMode
import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Fuzzy
import Keyboard.Extra as Key exposing (Key(..))
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


type SearchEntity
    = Context Context.Model
    | Project Project.Model


formView form m =
    let
        entityList =
            let
                contexts =
                    Model.getActiveContexts m
                        .|> Context

                projects =
                    Model.getActiveProjects m
                        .|> Project
            in
                projects ++ contexts

        getName entity =
            case entity of
                Project project ->
                    Project.getName project

                Context context ->
                    Context.getName context

        {-
           isMatch =
               getName >> String.dasherize >> String.startsWith (String.dasherize form.input)
           matchingEntityName =
              entityList
                  |> List.find isMatch
                  ?|> getName
                  ?= ""
        -}
        fuzzyResults =
            entityList
                .|> getName
                >> String.toLower
                >> Fuzzy.match [] [ " " ] (String.toLower form.input)
                |> List.zip entityList
                |> List.sortBy (Tuple.second >> (.score))

        maybeMatchingEntity =
            fuzzyResults
                |> List.head
                ?|> Tuple.first

        matchingEntityName =
            maybeMatchingEntity ?|> getName ?= "Not found"

        toViewType entity =
            case entity of
                Project project ->
                    Model.projectView project

                Context context ->
                    Model.contextView context

        keyHandler { key } =
            case key of
                Key.Enter ->
                    maybeMatchingEntity ?|> toViewType >> Msg.SwitchView ?= commonMsg.noOp

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
