module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Document
import Dom
import EditMode
import Entity.View
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import Maybe.Extra as Maybe
import Model.Internal as Model
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
import Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Entity.ViewModel exposing (EntityViewModel)
import Todo.View exposing (EditViewModel)
import Tuple2
import View.Shared exposing (..)
import ViewModel exposing (EntityView(..))
import WebComponents


filtered : ViewModel.Model -> Model -> Html Msg
filtered viewModel model =
    let
        createTodoView todo =
            Todo.View.initKeyed (viewModel.createTodoViewModel (tabindex -1) todo)
    in
        model
            |> Model.getFilteredTodoList
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


listView entityList viewModel =
    let
        projectVMs =
            viewModel.projects.entityList

        contextVMs =
            viewModel.contexts.entityList

        getMaybeContextVM context =
            contextVMs |> List.find (.id >> equals (Document.getId context))

        getMaybeProjectVM project =
            projectVMs |> List.find (.id >> equals (Document.getId project))

        focusedId =
            entityList
                |> List.find (Model.getEntityId >> equals viewModel.focusedEntityInfo.id)
                |> Maybe.orElse (List.head entityList)
                ?|> Model.getEntityId
                ?= ""

        isEntityFocused =
            Model.getEntityId >> equals focusedId

        createEntityView index entity =
            let
                focused =
                    isEntityFocused entity

                tabIndexAV =
                    getTabindexAV focused
            in
                case entity of
                    ContextEntity context ->
                        getMaybeContextVM context ?|> (Entity.View.initKeyed tabIndexAV viewModel)

                    ProjectEntity project ->
                        getMaybeProjectVM project ?|> (Entity.View.initKeyed tabIndexAV viewModel)

                    TodoEntity todo ->
                        Todo.View.initKeyed (viewModel.createTodoViewModel tabIndexAV todo) |> Just

        idList =
            entityList
                .|> Model.getEntityId
    in
        Keyed.node "div"
            [ class "entity-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (entityList
                |> List.indexedMap createEntityView
                |> List.filterMap identity
            )
