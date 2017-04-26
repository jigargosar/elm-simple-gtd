module Entity.ViewModel exposing (..)

import Context
import Dict
import Document
import EditMode exposing (EditMode)
import Lazy
import Model.Types exposing (Entity(ContextEntity, ProjectEntity), EntityAction(ToggleDeleted, NameChanged, Save, StartEditing), EntityStoreType(ContextEntityStoreType, ProjectEntityStoreType), EntityType(ContextEntityType, ProjectEntityType), MainViewType(ContextView, GroupByContextView, GroupByProjectView, ProjectView))
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
    , onActiveStateChanged : Bool -> Msg
    , startEditingMsg : Msg
    , onDeleteClicked : Msg
    , onSaveClicked : Msg
    , onNameChanged : String -> Msg
    , onCancelClicked : Msg
    }


createList config model =
    let
        todoListDict =
            Model.getActiveTodoListGroupedBy config.groupByFn model

        getTodoListWithGroupId id =
            todoListDict |> Dict.get id ?= []

        appendDeletedEntityList =
            if model.showDeleted then
                List.append # (Model.getDeletedEntityList config.entityType model)
            else
                identity

        --        entityList =
        --            Model.getActiveEntityList config.entityType model
        --                |> (::) config.nullEntity
        --                |> appendDeletedEntityList
        entityList =
            if model.showDeleted then
                Model.getDeletedEntityList config.entityType model
            else
                Model.getActiveEntityList config.entityType model
                    |> (::) config.nullEntity
    in
        entityList
            .|> create getTodoListWithGroupId config


create todoListByEntityId config entity =
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
                (onEntityAction ToggleDeleted)

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
        , onActiveStateChanged =
            (\bool ->
                if bool then
                    Msg.SetView (config.getViewType id)
                else
                    Msg.NoOp
            )
        , startEditingMsg = onEntityAction StartEditing
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = onEntityAction Save
        , onNameChanged = NameChanged >> onEntityAction
        , onCancelClicked = Msg.DeactivateEditingMode
        }


projectList : Model.Types.Model -> List ViewModel
projectList model =
    createList
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
    createList
        { groupByFn = Todo.getContextId
        , entityType = ContextEntityType
        , entityWrapper = ContextEntity
        , nullEntity = Context.null
        , isNull = Context.isNull
        , getViewType = ContextView
        , maybeEditModel = Model.getMaybeEditModelForEntityType ContextEntityType model
        }
        model


context model =
    { vmList = contextList model
    , viewType = GroupByContextView
    , title = "Contexts"
    , showDeleted = model.showDeleted
    , onAddClicked = Msg.NewProject
    }


project model =
    { vmList = projectList model
    , viewType = GroupByProjectView
    , title = "Project"
    , showDeleted = model.showDeleted
    , onAddClicked = Msg.NewProject
    }
