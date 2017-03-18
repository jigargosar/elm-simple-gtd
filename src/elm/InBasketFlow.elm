module InBasketFlow exposing (..)

import Flow
import Main.Msg exposing (Msg(OnFlowTrashItClicked))


inBasketFlow =
    Flow.branch "Is it Actionable ?"
        (Flow.branch "Can be done under 2 mins?"
            (Flow.confirmAction "Do it now?"
                (Flow.action "Timer Started, Go Go Go !!!" OnFlowTrashItClicked)
            )
            (Flow.action "Involves Multiple Steps?" OnFlowTrashItClicked)
        )
        (Flow.branch "Is it worth keeping?"
            (Flow.branch "Could Require actionNode Later ?"
                (Flow.action "Move to SomDay/Maybe List?" OnFlowTrashItClicked)
                (Flow.action "Move to Reference?" OnFlowTrashItClicked)
            )
            (Flow.action "Trash it ?" OnFlowTrashItClicked)
        )
        |> Flow.init


type alias Model =
    Flow.Model Msg


modelConstructor todoList =
    inBasketFlow


init todoList =
    modelConstructor todoList


update =
    Flow.update
