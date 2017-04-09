module View.Project exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types
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
    }


createVM todoByGroupIdDict model =
    let
        id =
            Project.getId model

        todoList =
            todoByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        name =
            let
                name =
                    Project.getName model
            in
                if String.Extra.isBlank name then
                    "<Blank Name>"
                else
                    name
    in
        { id = id
        , name = name
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
            Model.getActiveTodoListGroupedByProjectId model
    in
        Model.getActiveProjects model
            .|> createVM todoByGroupIdDict
            |> prependDefaultVM todoByGroupIdDict
