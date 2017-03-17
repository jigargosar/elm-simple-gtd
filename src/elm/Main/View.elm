module Main.View exposing (appView)

import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Flow
import Flow.View
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import TodoCollection.Todo as Todo
import TodoCollection.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Flow.Model as Flow exposing (Node)


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

        ProcessInBasketViewState flowModel ->
            flowView flowModel


flowView flowModel =
    div [] [ Flow.View.flowDialogView OnFlowButtonClicked flowModel ]


todoListView m =
    div []
        [ TodoCollection.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
        ]
