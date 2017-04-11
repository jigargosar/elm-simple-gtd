module View.Project exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types exposing (Entity(ProjectEntity), EntityAction(Delete), MainViewType(ProjectView))
import Msg exposing (Msg)
import Project
import String.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Todo


type alias ViewModel =
    { id : Project.Id
    , name : Project.Name
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    , onClick : Msg
    , onDeleteClicked : Msg
    , onSettingsClicked : Msg
    }


createVM todoListByGroupIdDict model =
    let
        entity =
            ProjectEntity model

        id =
            Project.getId model

        todoList =
            todoListByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        isNull =
            Project.isNull model

        onDeleteClicked =
            if isNull then
                (Msg.NoOp)
            else
                (Msg.OnEntityAction id entity Delete)
    in
        { id = id
        , name = Project.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (ProjectView id)
        , onSettingsClicked = Msg.OnSettingsClicked entity
        , onDeleteClicked = onDeleteClicked
        }


vmList : Model.Types.Model -> List ViewModel
vmList model =
    let
        todoByGroupIdDict =
            Model.getActiveTodoListGroupedByProjectId model
    in
        Model.getActiveProjects model
            |> (::) Context.null
            .|> createVM todoByGroupIdDict
