module View.Entity exposing (..)

import Dict
import Model.Types exposing (Entity, EntityAction(Delete), MainViewType)
import Msg exposing (Msg)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias ViewModel =
    { id : String
    , name : String
    , todoList : List Todo.Model
    , isEmpty : Bool
    , count : Int
    , onClick : Msg
    , onDeleteClicked : Msg
    , onSettingsClicked : Msg
    }


type alias ModelConfig a =
    { createEntity : Entity
    , getId : a -> String
    , isNull : a -> Bool
    , getName : a -> String
    , getViewType : String -> MainViewType
    }


createVM todoListByGroupIdDict modelConfig model =
    let
        entity =
            modelConfig.createEntity model

        id =
            modelConfig.getId model

        todoList =
            todoListByGroupIdDict |> Dict.get id ?= []

        count =
            List.length todoList

        isNull =
            modelConfig.isNull model

        onDeleteClicked =
            if isNull then
                (Msg.NoOp)
            else
                (Msg.OnEntityAction id entity Delete)
    in
        { id = id
        , name = modelConfig.getName model
        , todoList = todoList
        , isEmpty = count == 0
        , count = List.length todoList
        , onClick = Msg.SetView (modelConfig.getViewType id)
        , onSettingsClicked = Msg.OnSettingsClicked entity
        , onDeleteClicked = onDeleteClicked
        }
