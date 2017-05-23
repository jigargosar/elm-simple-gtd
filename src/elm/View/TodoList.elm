module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Document
import Dom
import EditMode
import Entity
import GroupEntity.View
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Maybe.Extra as Maybe
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Project
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import GroupEntity.ViewModel exposing (EntityViewModel)
import Todo.View exposing (EditViewModel)
import Tuple2
import View.Shared exposing (..)
import ViewModel
import WebComponents
import Entity.ViewModel


filtered : ViewModel.Model -> Model -> Html Msg
filtered viewModel model =
    let
        createTodoView todo =
            Todo.View.initKeyed (viewModel.createTodoViewModel (tabindex -1) todo)
    in
        model
            |> Model.getTodoListForCurrentView
            .|> createTodoView
            |> Keyed.node "paper-listbox"
                [ stringProperty "selected" "0"
                , stringProperty "selectedAttribute" "selected"
                ]


getTabindexAV focused =
    let
        tabindexValue =
            if focused then
                0
            else
                -1
    in
        tabindex tabindexValue


isEntityFocusedInEntityList entityList viewModel =
    let
        focusedId =
            entityList
                |> List.find (Model.getEntityId >> equals viewModel.focusedEntityInfo.id)
                |> Maybe.orElse (List.head entityList)
                ?|> Model.getEntityId
                ?= ""
    in
        Model.getEntityId >> equals focusedId


listView entityList viewModel =
    let
        isEntityFocused =
            isEntityFocusedInEntityList entityList viewModel

        createEntityView index entity =
            let
                tabIndexAV =
                    getTabindexAV (isEntityFocused entity)
            in
                case entity of
                    Entity.ContextEntity context ->
                        Entity.ViewModel.contextGroup {- viewModel tabIndexAV -} context
                            |> (GroupEntity.View.initKeyed tabIndexAV viewModel)

                    Entity.ProjectEntity project ->
                        Entity.ViewModel.projectGroup project |> (GroupEntity.View.initKeyed tabIndexAV viewModel)

                    Entity.TodoEntity todo ->
                        Todo.View.initKeyed (viewModel.createTodoViewModel tabIndexAV todo)

        idList =
            entityList
                .|> Model.getEntityId
    in
        Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (entityList
                |> List.indexedMap createEntityView
            )
