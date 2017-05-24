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


createVMList entityList model appViewModel =
    let
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

        createVM entity =
            let
                tabIndexAV =
                    getTabindexAV entity
            in
                case entity of
                    Entity.ContextEntity context ->
                        EntityList.createContextGroupViewModel tabIndexAV context
                            |> Group

                    Entity.ProjectEntity project ->
                        EntityList.createProjectGroupViewModel tabIndexAV project
                            |> Group

                    Entity.TodoEntity todo ->
                        appViewModel.createTodoViewModel tabIndexAV todo
                            |> Todo
    in
        entityList .|> createVM


listView viewType model appViewModel =
    let
        entityList =
            Model.createViewEntityList viewType model

        vmList =
            createVMList entityList model appViewModel

        createEntityView vm =
            case vm of
                Group vm ->
                    GroupEntity.View.initKeyed appViewModel vm

                Todo vm ->
                    Todo.View.initKeyed vm
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (vmList
                .|> createEntityView
            )
