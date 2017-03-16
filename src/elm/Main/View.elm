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
        [ header todo
        , h2 [] [ text "Is it Actionable?" ]
        , yesNoButtons ProcessAsActionable ProcessAsNotActionable todo
        ]


processAsActionableView todo =
    div []
        [ header todo
        , h2 [] [ text "Actionable >> Can be done under 2 mins" ]
        , yesNoButtons ProcessAsActionable ProcessAsNotActionable todo
        ]


processAsNotActionableView todo =
    div []
        [ header todo
        , h2 [] [ text "NotActionable >> Eliminate ?" ]
        , yesNoButtons ProcessAsActionable ProcessAsNotActionable todo
        ]


header todo =
    div []
        [ h3 []
            [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        ]


onClickUpdatePM processingModel todo =
    OnUpdateProcessingModel (processingModel todo) |> onClick


yesNoButtons pmYes pmNo todo =
    div []
        [ button [ onClickUpdatePM pmYes todo ] [ text "YES" ]
        , button [ onClickUpdatePM pmNo todo ] [ text "NO" ]
        ]
