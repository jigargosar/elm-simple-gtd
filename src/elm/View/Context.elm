module View.Context exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types exposing (EntityAction(Delete, StartEditing), Entity(ContextEntity), MainViewType(ContextView))
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
    , isEditable : Bool
    , onDeleteClicked : Msg
    , onClick : Msg
    , onSettingsClicked : Msg
    }


createVM todoListByGroupIdDict model =
    let
        id =
            Context.getId model

        todoList =
            todoListByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        entity =
            (ContextEntity model)
    in
        { id = id
        , name = Context.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , isEditable = True
        , onDeleteClicked = Msg.OnEntityAction id entity Delete
        , onClick = Msg.SetView (ContextView id)
        , onSettingsClicked = Msg.OnSettingsClicked entity
        }


createNullVM todoListByGroupIdDict model =
    let
        entity =
            ContextEntity model

        id =
            Context.getId model

        todoList =
            todoListByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList
    in
        { id = id
        , name = Context.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = count
        , isEditable = False
        , onDeleteClicked = Msg.NoOp
        , onClick = Msg.SetView (ContextView id)
        , onSettingsClicked = Msg.OnSettingsClicked entity
        }


prependNullModelVM todoByContextIdDict vmList =
    let
        context =
            Context.null

        entity =
            ContextEntity context

        id =
            Context.getId context

        todoList =
            todoByContextIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        nullVM =
            { id = id
            , name = Context.getName context
            , todoList = todoList
            , isEmpty = count == 0
            , count = count
            , isEditable = False
            , onDeleteClicked = Msg.NoOp
            , onClick = Msg.SetView (ContextView id)
            , onSettingsClicked = Msg.OnSettingsClicked entity
            }
    in
        nullVM :: vmList


vmList : Model.Types.Model -> List ViewModel
vmList model =
    let
        todoByContextIdDict =
            Model.getActiveTodoListGroupedByContextId model
    in
        Model.getActiveContexts model
            .|> createVM todoByContextIdDict
            |> prependNullModelVM todoByContextIdDict
