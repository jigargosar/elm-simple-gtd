module EntityList.View exposing (..)

import Document
import Entity
import EntityList
import EntityList.GroupViewModel
import Html
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
import Msg exposing (Msg)
import Todo.View exposing (TodoViewModel)


isCursorAtEntityInEntityList entityList viewModel =
    let
        focusedId =
            getFocusInId entityList viewModel
    in
        Model.getEntityId >> equals focusedId


getFocusInId entityList viewModel =
    entityList
        |> List.find (Model.getEntityId >> equals viewModel.focusedEntityInfo.id)
        |> Maybe.orElse (List.head entityList)
        ?|> Model.getEntityId
        ?= ""


type ViewModel
    = Group EntityList.GroupViewModel.ViewModel
    | Todo TodoViewModel


type alias EntityViewModel =
    { id : Document.Id
    , onFocusIn : Msg
    , onFocus : Msg
    , onBlur : Msg
    , startEditingMsg : Msg
    , toggleDeleteMsg : Msg
    , startEditingMsg : Msg
    , tabIndexAV : Html.Attribute Msg
    }


listView viewType model appViewModel =
    let
        entityList =
            Model.createViewEntityList viewType model

        focusInId =
            getFocusInId entityList appViewModel

        getTabindexAV entity =
            let
                tabindexValue =
                    if Model.getEntityId entity == focusInId then
                        0
                    else
                        -1
            in
                tabindex tabindexValue

        createEntityView index entity =
            let
                tabIndexAV =
                    getTabindexAV entity
            in
                case entity of
                    Entity.ContextEntity context ->
                        EntityList.createContextGroupViewModel {- viewModel tabIndexAV -} context
                            |> (GroupEntity.View.initKeyed tabIndexAV appViewModel)

                    Entity.ProjectEntity project ->
                        EntityList.createProjectGroupViewModel project
                            |> (GroupEntity.View.initKeyed tabIndexAV appViewModel)

                    Entity.TodoEntity todo ->
                        Todo.View.initKeyed (appViewModel.createTodoViewModel tabIndexAV todo)
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (entityList
                |> List.indexedMap createEntityView
            )
