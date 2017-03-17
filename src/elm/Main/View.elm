module Main.View exposing (elmAppView)

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


elmAppView m =
    div [] [ getInBasketFlowModel m |> Flow.View.flowDialogView OnInBasketFlowButtonClicked ]


todoListView m =
    div []
        [ TodoCollection.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
        ]
