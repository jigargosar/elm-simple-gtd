module EntityList.View exposing (..)

import Entity
import EntityList
import EntityList.ViewModel
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


hasFocusInEntityList entityList viewModel =
    let
        focusedId =
            entityList
                |> List.find (Model.getEntityId >> equals viewModel.focusedEntityInfo.id)
                |> Maybe.orElse (List.head entityList)
                ?|> Model.getEntityId
                ?= ""
    in
        Model.getEntityId >> equals focusedId


listView viewType model mainViewModel =
    let
        vm =
            EntityList.ViewModel.list viewType mainViewModel model

        entityList =
            Model.createViewEntityList viewType model

        hasFocusIn =
            hasFocusInEntityList entityList mainViewModel

        createEntityView index entity =
            let
                tabIndexAV =
                    getTabindexAV (hasFocusIn entity)
            in
                case entity of
                    Entity.ContextEntity context ->
                        EntityList.createContextGroupViewModel {- viewModel tabIndexAV -} context
                            |> (GroupEntity.View.initKeyed tabIndexAV mainViewModel)

                    Entity.ProjectEntity project ->
                        EntityList.createProjectGroupViewModel project
                            |> (GroupEntity.View.initKeyed tabIndexAV mainViewModel)

                    Entity.TodoEntity todo ->
                        Todo.View.initKeyed (mainViewModel.createTodoViewModel tabIndexAV todo)
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (entityList
                |> List.indexedMap createEntityView
            )
