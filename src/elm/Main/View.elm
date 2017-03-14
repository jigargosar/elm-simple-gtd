module Main.View exposing (elmAppView)

import DecodeExtra exposing (traceDecoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todos.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)

todoListViewConfig = { onAdd = OnAddTodo
    , onDelete = OnDeleteTodo
    , onEdit = OnEditTodo
    }

elmAppView m =
    div []
        [ div [] [ text "Hello" ]
        , Todos.View.listView todoListViewConfig (getTodosModel m)
        ]
