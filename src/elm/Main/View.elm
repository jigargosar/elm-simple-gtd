module Main.View exposing (elmAppView)

import DecodeExtra exposing (traceDecoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import TodoCollection.Todo as Todo
import TodoCollection.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)


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
    , onProcessButtonClicked = OnProcessButtonClicked
    }


elmAppView m =
    case Main.Model.getProcessingModel m of
        NotProcessing ->
            div []
                [ TodoCollection.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
                ]

        StartProcessing index todoList todo ->
            startProcessingView todo


startProcessingView todo =
    div []
        [ h3 []
            [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        ]
