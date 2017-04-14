module Entity.ViewModel exposing (..)

import Context
import Dict
import Document
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
    , isDeleted : Bool
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    , navigateToEntityMsg : Msg
    , startEditingMsg : Msg
    , onDeleteClicked : Msg
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
            Model.getActiveEntityList config.entityType model
                |> (::) config.nullEntity
    in
        entityList
            .|> createViewModel getTodoListWithGroupId config


createViewModel todoListByEntityId config entity =
    let
        id =
            Document.getId entity

        onEntityAction =
            Msg.OnEntityAction (config.entityWrapper entity)

        todoList =
            todoListByEntityId id

        count =
            List.length todoList

        isNull =
            config.isNull entity

        onDeleteClicked =
            if isNull then
                (Msg.NoOp)
            else
                (onEntityAction Delete)

        maybeEditModel =
            config.maybeEditModel
                ?+> (\editModel ->
                        if editModel.id == id then
                            Just editModel
                        else
                            Nothing
                    )
    in
        { id = id
        , name = entity.name
        , isDeleted = Document.isDeleted entity
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , navigateToEntityMsg = Msg.SetView (config.getViewType id)
        , startEditingMsg = onEntityAction StartEditing
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = onEntityAction Save
        , onNameChanged = NameChanged >> onEntityAction
        , onCancelClicked = Msg.DeactivateEditingMode
        }


projectList : Model.Types.Model -> List ViewModel
projectList model =
    createViewModelList
        { groupByFn = Todo.getProjectId
        , entityType = ProjectEntityType
        , entityWrapper = ProjectEntity
        , nullEntity = Project.null
        , isNull = Project.isNull
        , getViewType = ProjectView
        , maybeEditModel = Model.getMaybeEditModelForEntityType ProjectEntityType model
        }
        model


contextList : Model.Types.Model -> List ViewModel
contextList model =
    createViewModelList
        { groupByFn = Todo.getContextId
        , entityType = ContextEntityType
        , entityWrapper = ContextEntity
        , nullEntity = Context.null
        , isNull = Context.isNull
        , getViewType = ContextView
        , maybeEditModel = Model.getMaybeEditModelForEntityType ContextEntityType model
        }
        model
