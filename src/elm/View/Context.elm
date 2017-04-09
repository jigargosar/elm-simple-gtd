module View.Context exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types
import Msg exposing (Msg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Todo


type alias ViewModel =
    { id : Context.Id
    , name : Context.Name
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    }


createContextViewModel todoByContextIdDict context =
    let
        id =
            Context.getId context

        todoList =
            todoByContextIdDict |> Dict.get id ?= []

        count =
            List.length todoList
    in
        { id = id
        , name = Context.getName context
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        }


prependInboxContextVM todoByContextIdDict contextVMs =
    let
        id =
            ""

        todoList =
            todoByContextIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        inboxVM =
            { id = id
            , name = "Inbox"
            , todoList = todoList
            , isEmpty = count == 0
            , count = count
            }
    in
        inboxVM :: contextVMs


vmList : Model.Types.Model -> List ViewModel
vmList model =
    let
        todoByContextIdDict =
            Model.getActiveTodoListGroupedByContextId model
    in
        Model.getActiveContexts model
            .|> createContextViewModel todoByContextIdDict
            |> prependInboxContextVM todoByContextIdDict
