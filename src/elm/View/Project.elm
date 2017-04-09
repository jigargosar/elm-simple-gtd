module View.Project exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types
import Msg exposing (Msg)
import Project exposing (ProjectId, ProjectName)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Todo.Types exposing (Todo)


type alias ViewModel =
    { id : ProjectId
    , name : ProjectName
    , todoList : List Todo
    , isEmpty : Bool
    , count : Int
    }


createVM todoByGroupIdDict model =
    let
        id =
            Project.getId model

        todoList =
            todoByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList
    in
        { id = id
        , name = Project.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        }


prependDefaultVM todoByGroupIdDict vmList =
    let
        id =
            ""

        todoList =
            todoByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        defaultVM =
            { id = id
            , name = "<No Project>"
            , todoList = todoList
            , isEmpty = count == 0
            , count = count
            }
    in
        defaultVM :: vmList


vmList : Model.Types.Model -> List ViewModel
vmList model =
    let
        todoByGroupIdDict =
            Model.getActiveTodoListGroupedByContextId model
    in
        Model.getActiveProjects model
            .|> createVM todoByGroupIdDict
            |> prependDefaultVM todoByGroupIdDict
