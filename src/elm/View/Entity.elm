module View.Entity exposing (..)

import Context
import Dict
import EditMode exposing (EditMode)
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
    }


type alias ModelConfig a =
    { createEntity : Entity
    , getId : a -> String
    , isNull : a -> Bool
    , getName : a -> String
    , getViewType : String -> MainViewType
    }


createVM todoListByEntityId modelConfig model =
    let
        entity =
            modelConfig.createEntity model

        todoList =
            todoListByEntityId model.id

        count =
            List.length todoList

        isNull =
            modelConfig.isNull model

        onDeleteClicked =
            if isNull then
                (Msg.NoOp)
            else
                (Msg.OnEntityAction entity Delete)
    in
        { id = model.id
        , name = modelConfig.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (modelConfig.getViewType model.id)
        , onSettingsClicked = (Msg.OnEntityAction entity StartEditing)
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = (Msg.OnEntityAction entity Save)
        , onNameChanged = NameChanged >> Msg.OnEntityAction entity
        }


createProjectVMs : Model.Types.Model -> List ViewModel
createProjectVMs model =
    let
        getTodoListByGroupId id =
            let
                dict =
                    Model.getActiveTodoGroupedBy Todo.getProjectId model
            in
                dict |> Dict.get id ?= []

        projectVMS =
            Model.getActiveEntityList ProjectEntityStoreType model
                |> (::) Project.null

        vmConfig =
            { createEntity = ProjectEntity
            , getId = Project.getId
            , isNull = Project.isNull
            , getName = Project.getName
            , getViewType = ProjectView
            }
    in
        projectVMS .|> createVM getTodoListByGroupId vmConfig


createContextVMS : Model.Types.Model -> List ViewModel
createContextVMS model =
    let
        todoListByEntityId id =
            let
                dict =
                    Model.getActiveTodoGroupedBy Todo.getContextId model
            in
                dict |> Dict.get id ?= []
    in
        Model.getActiveEntityList ContextEntityStoreType model
            |> (::) Context.null
            .|> createVM todoListByEntityId
                    { createEntity = ContextEntity
                    , getId = Context.getId
                    , isNull = Context.isNull
                    , getName = Context.getName
                    , getViewType = ContextView
                    }
