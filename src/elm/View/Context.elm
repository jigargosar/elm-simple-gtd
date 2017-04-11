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
    , onEditClicked : Msg
    , onDeleteClicked : Msg
    , onClick : Msg
    }


createContextViewModel todoByContextIdDict context =
    let
        id =
            Context.getId context

        todoList =
            todoByContextIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        contextEntity =
            (ContextEntity context)
    in
        { id = id
        , name = Context.getName context
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , isEditable = True
        , onEditClicked = Msg.OnEntityAction id contextEntity StartEditing
        , onDeleteClicked = Msg.OnEntityAction id contextEntity Delete
        , onClick = Msg.SetView (ContextView id)
        , onSettingsClicked = Msg.OnSettingsClicked contextEntity
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
            , isEditable = False
            , onEditClicked = Msg.NoOp
            , onDeleteClicked = Msg.NoOp
            , onClick = Msg.SetView (ContextView id)
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
