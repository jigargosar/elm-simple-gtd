module EntityList.ViewModel exposing (..)

import Document
import Entity exposing (Entity)
import EntityList
import EntityList.GroupViewModel
import GroupEntity.View
import Html
import Html.Attributes exposing (tabindex)
import Model
import Msg exposing (Msg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.View exposing (TodoViewModel)
import ViewModel


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


list : Entity.ListViewType -> ViewModel.Model -> Model.Model -> List ViewModel
list viewType appViewModel model =
    let
        entityList =
            Model.createViewEntityList viewType model

        isFocused =
            isEntityFocusedInEntityList entityList appViewModel

        create entity =
            let
                tabIndexAV =
                    getTabindexAV (isFocused entity)
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
        []
