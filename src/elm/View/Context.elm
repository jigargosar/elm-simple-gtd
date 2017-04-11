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
        entity =
            ContextEntity model

        id =
            Context.getId model

        todoList =
            todoListByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        isNull =
            Context.isNull model

        ( onDeleteClicked, isEditable ) =
            if isNull then
                ( Msg.NoOp, False )
            else
                ( Msg.OnEntityAction id entity Delete, True )
    in
        { id = id
        , name = Context.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , isEditable = isEditable
        , onDeleteClicked = onDeleteClicked
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


vmList : Model.Types.Model -> List ViewModel
vmList model =
    let
        todoByContextIdDict =
            Model.getActiveTodoListGroupedByContextId model
    in
        Model.getActiveContexts model
            |> (::) Context.null
            .|> createVM todoByContextIdDict
