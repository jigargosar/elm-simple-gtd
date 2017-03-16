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

        StartProcessing todo ->
            startProcessingView todo

        ProcessAsActionable todo ->
            processAsActionableView todo

        ProcessAsNotActionable todo ->
            processAsNotActionableView todo


startProcessingView todo =
    div []
        [ h3 []
            [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        , h2 [] [ text "Is it Actionable?" ]
        , button [ onClickUpdatePM ProcessAsActionable todo ] [ text "YES" ]
        , button [ onClickUpdatePM ProcessAsNotActionable todo ] [ text "NO" ]
        ]


onClickUpdatePM processingModel todo =
    OnUpdateProcessingModel (processingModel todo) |> onClick


processAsActionableView todo =
    div []
        [ h3 []
            [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        , h2 [] [ text "Can be done under 2 mins" ]
        , button [ onClickUpdatePM ProcessAsActionable todo ] [ text "YES" ]
        , button [ onClickUpdatePM ProcessAsNotActionable todo ] [ text "NO" ]
        ]


processAsNotActionableView todo =
    div []
        [ h3 []
            [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        , h2 [] [ text "Eliminate ?" ]
        , button [ onClickUpdatePM ProcessAsActionable todo ] [ text "YES" ]
        , button [ onClickUpdatePM ProcessAsNotActionable todo ] [ text "NO" ]
        ]
