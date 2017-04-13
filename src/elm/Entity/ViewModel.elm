module Entity.ViewModel exposing (..)

import Context
import Dict
import EditMode exposing (EditMode)
import Lazy
import Model.Types exposing (Entity(ContextEntity, ProjectEntity), EntityAction(Delete, NameChanged, Save, StartEditing), EntityStoreType(ContextEntityStoreType, ProjectEntityStoreType), EntityType(ContextEntityType, ProjectEntityType), MainViewType(ContextView, ProjectView))
import Msg exposing (Msg)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Project


type alias ViewModel =
    { id : String
    , name : String
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    , onClick : Msg
    , onDeleteClicked : Msg
    , onSettingsClicked : Msg
    , onSaveClicked : Msg
    , onNameChanged : String -> Msg
    , onCancelClicked : Msg
    }


createViewModelList config model =
    let
        todoListDict =
            Model.getActiveTodoListGroupedBy config.groupByFn model

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        entityList =
            Model.getActiveEntityList config.storeType model
                |> (::) config.nullEntity
    in
        entityList
            .|> createViewModel getTodoListWithGroupId config


createViewModel todoListByEntityId config model =
    let
        onEntityAction =
            Msg.OnEntityAction (config.entityWrapper model)

        todoList =
            todoListByEntityId model.id

        count =
            List.length todoList

        isNull =
            config.isNull model

        onDeleteClicked =
            if isNull then
                (Msg.NoOp)
            else
                (onEntityAction Delete)
    in
        { id = model.id
        , name = model.name
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (config.getViewType model.id)
        , onSettingsClicked = onEntityAction StartEditing
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = onEntityAction Save
        , onNameChanged = NameChanged >> onEntityAction
        , onCancelClicked = Msg.DeactivateEditingMode
        }


createProjectViewModelList : Model.Types.Model -> List ViewModel
createProjectViewModelList =
    createViewModelList
        { groupByFn = Todo.getProjectId
        , storeType = ProjectEntityStoreType
        , entityWrapper = ProjectEntity
        , nullEntity = Project.null
        , isNull = Project.isNull
        , getViewType = ProjectView
        }


createContextViewModelList : Model.Types.Model -> List ViewModel
createContextViewModelList =
    createViewModelList
        { groupByFn = Todo.getContextId
        , storeType = ContextEntityStoreType
        , entityWrapper = ContextEntity
        , nullEntity = Context.null
        , isNull = Context.isNull
        , getViewType = ContextView
        }
