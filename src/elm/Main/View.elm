module Main.View exposing (elmAppView)

import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import InBasketFlow
import InBasketFlow.View
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import TodoCollection.Todo as Todo
import TodoCollection.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import InBasketFlow.Model as InBasketFlow


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


rootNode =
    InBasketFlow.branch "Is it Actionable ?"
        (InBasketFlow.branch "Can be done under 2 mins?"
            (InBasketFlow.confirmAction "Do it now?"
                (InBasketFlow.action "Timer Started, Go Go Go !!!" OnTrashItYesClicked)
            )
            (InBasketFlow.action "Involves Multiple Steps?" OnTrashItYesClicked)
        )
        (InBasketFlow.branch "Is it worth keeping?"
            (InBasketFlow.branch "Could Require actionNode Later ?"
                (InBasketFlow.action "Move to SomDay/Maybe List?" OnTrashItYesClicked)
                (InBasketFlow.action "Move to Reference?" OnTrashItYesClicked)
            )
            (InBasketFlow.action "Trash it ?" OnTrashItYesClicked)
        )



--testModel =
--    InBasketFlow.init rootNode
--        |> logNode "start"
--        |> InBasketFlow.onNo
--        ?|> logNode "no"
--        ?+> InBasketFlow.onNo
--        ?|> logNode "no"
--
--        ?+> InBasketFlow.onYes
--        ?|> logNode "yes"


logNode =
    tapLog (InBasketFlow.getQuestion)

--flowViewConfig = {
--        onClick = OnInBasketFlowButtonClicked
--    }

elmAppView m =
    div [] [ getInBasketFlowModel m |> InBasketFlow.View.flowDialogView ]


todoListView m =
    div []
        [ TodoCollection.View.allTodosView todoListViewConfig (getEditMode m) (getTodoCollection m)
        ]
