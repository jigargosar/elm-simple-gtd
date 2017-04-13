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
                (modelConfig.onEntityAction Delete)
    in
        { id = model.id
        , name = model.name
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (modelConfig.getViewType model.id)
        , onSettingsClicked = modelConfig.onEntityAction StartEditing
        , onDeleteClicked = onDeleteClicked
        , onSaveClicked = modelConfig.onEntityAction Save
        , onNameChanged = NameChanged >> modelConfig.onEntityAction
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

        vmConfig model =
            { onEntityAction = Msg.OnEntityAction (ProjectEntity model)
            , isNull = Project.isNull
            , getViewType = ProjectView
            }
    in
        projectVMS .|> (\model -> createVM getTodoListByGroupId (vmConfig model) model)


createContextVMS : Model.Types.Model -> List ViewModel
createContextVMS model =
    let
        todoListByGroupId id =
            let
                dict =
                    Model.getActiveTodoGroupedBy Todo.getContextId model
            in
                dict |> Dict.get id ?= []
    in
        Model.getActiveEntityList ContextEntityStoreType model
            |> (::) Context.null
            .|> (\model ->
                    createVM todoListByGroupId
                        { onEntityAction = Msg.OnEntityAction (ContextEntity model)
                        , isNull = Context.isNull
                        , getViewType = ContextView
                        }
                        model
                )
