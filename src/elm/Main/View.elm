module Main.View exposing (appView)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow

import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import TodoStore.Todo as Todo
import TodoStore.View
import Flow.Model as Flow exposing (Node)
import InBasketFlow
import InBasketFlow.View


todoListViewConfig =
    { onAddTodoClicked = OnAddTodoClicked
    , onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoEnterPressed = OnEditTodoEnterPressed
    , onNewTodoTextChanged = OnNewTodoTextChanged
    , onNewTodoBlur = OnNewTodoBlur
    , onNewTodoEnterPressed = OnNewTodoEnterPressed
    }


appView m =
    div []
        [ toolbarView m
        , centerView m
        ]


toolbarView m =
    div []
        [ button [ onClick OnShowTodoList ] [ text "Show Todo List" ]
        , button [ onClick OnProcessInBasket ] [ text "Process In-Basket" ]
        ]


centerView m =
    case getViewState m of
        TodoListViewState ->
            todoListView m

        InBasketFlowViewState inBasketFlowModel ->
            InBasketFlow.View.view inBasketFlowModel


todoListView m =
    div []
        [ TodoStore.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
        ]
