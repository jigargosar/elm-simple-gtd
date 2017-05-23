module EntityList.View exposing (..)

import Entity
import EntityList
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Ext.Keyboard exposing (onKeyDown)
import GroupEntity.View
import Html.Attributes exposing (class, tabindex)
import Html.Keyed
import Model
import Msg
import Todo.View


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
                        EntityList.createContextGroupViewModel {- viewModel tabIndexAV -} context
                            |> (GroupEntity.View.initKeyed tabIndexAV viewModel)

                    Entity.ProjectEntity project ->
                        EntityList.createProjectGroupViewModel project
                            |> (GroupEntity.View.initKeyed tabIndexAV viewModel)

                    Entity.TodoEntity todo ->
                        Todo.View.initKeyed (viewModel.createTodoViewModel tabIndexAV todo)
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (entityList
                |> List.indexedMap createEntityView
            )
