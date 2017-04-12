module View.Entity exposing (..)

import Context
import Dict
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

        id =
            modelConfig.getId model

        todoList =
            todoListByEntityId |> Dict.get id ?= []

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
        { id = id
        , name = modelConfig.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (modelConfig.getViewType id)
        , onSettingsClicked = (Msg.OnEntityAction entity StartEditing)
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = (Msg.OnEntityAction entity Save)
        , onNameChanged = NameChanged >> Msg.OnEntityAction entity
        }


createProjectVMs : Model.Types.Model -> List ViewModel
createProjectVMs model =
    let
        todoListByEntityId =
            Model.getActiveTodoGroupedBy Todo.getProjectId model
    in
        Model.getActiveEntityList ProjectEntityStoreType model
            |> (::) Project.null
            .|> createVM todoListByEntityId
                    { createEntity = ProjectEntity
                    , getId = Project.getId
                    , isNull = Project.isNull
                    , getName = Project.getName
                    , getViewType = ProjectView
                    }


createContextVMS : Model.Types.Model -> List ViewModel
createContextVMS model =
    let
        todoListByEntityId =
            Model.getActiveTodoGroupedBy Todo.getContextId model
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
