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

        ProcessAsTrash todo ->
            processAsTrashView todo

        ProcessAsWorthKeeping todo ->
            processAsWorthKeeping todo

        ProcessAsSomeDay todo ->
            processAsSomeDay todo

        ProcessAsReference todo ->
            processAsReference todo


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
        , h2 [] [ text "Not Actionable >> Is it worth keeping ?" ]
        , yesNoButtons ProcessAsWorthKeeping ProcessAsTrash todo
        ]


processAsTrashView todo =
    div []
        [ header todo
        , h2 [] [ text "Not Actionable >> Not Worth Keeping >> Trash it ?" ]
        , lastActionButtons StartProcessing todo
        ]


processAsWorthKeeping todo =
    div []
        [ header todo
        , h2 [] [ text "Not Actionable >> Worth Keeping >> Could Require Action Later ?" ]
        , yesNoButtons ProcessAsSomeDay ProcessAsReference todo
        ]


processAsSomeDay todo =
    div []
        [ header todo
        , h2 [] [ text "Not Actionable >> Worth Keeping >> Move to SomDay/Maybe List?" ]
        , lastActionButtons ProcessAsWorthKeeping todo
        ]


processAsReference todo =
    div []
        [ header todo
        , h2 [] [ text "Not Actionable >> Worth Keeping >> Move to Reference ?" ]
        , lastActionButtons StartProcessing todo
        ]


header todo =
    div []
        [ h3 [] [ text "Processing : " ]
        , h1 [] [ Todo.getText todo |> text ]
        ]


onClickUpdatePM processingModel todo =
    OnUpdateProcessingModel (processingModel todo) |> onClick


yesNoButtons pmYes pmNo todo =
    div []
        [ button [ onClickUpdatePM pmYes todo ] [ text "YES" ]
        , button [ onClickUpdatePM pmNo todo ] [ text "NO" ]
        ]


lastActionButtons pmNo todo =
    div []
        [ button [ OnUpdateProcessingModel NotProcessing |> onClick ] [ text "YES" ]
        , button [ onClickUpdatePM pmNo todo ] [ text "NO" ]
        ]
