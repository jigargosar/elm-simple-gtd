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


todoListViewConfig =
    { onAddTodoClicked = OnAddTodoClicked
    , onDelete = OnDeleteTodo
    , onEdit = OnEditTodo
    , onNewTodoTextChanged = OnNewTodoTextChanged
    , onNewTodoBlur = OnNewTodoBlur
    , onNewTodoEnterPressed = OnNewTodoEnterPressed
    }


elmAppView m =
    div []
        [ div [] [ text "Hello" ]
        , div [] [ text ("editMode = " ++ (toString m.editMode)) ]
        , Todos.View.listView todoListViewConfig (getEditMode m) (getTodosModel m)
        ]
