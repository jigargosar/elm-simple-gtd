module InBasketFlow exposing (..)

import InBasketFlow.Model exposing (Tracker, actionNode, branchNode, confirmActionNode, onNo, onYes, createTracker)
import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


rootNode =
    branchNode "Is it Actionable ?"
        (branchNode "Can be done under 2 mins?"
            (confirmActionNode "Do it now?"
                (actionNode "Timer Started, Go Go Go !!!")
            )
            (actionNode "Involves Multiple Steps?")
        )
        (branchNode "Is it worth keeping?"
            (branchNode "Could Require actionNode Later ?"
                (actionNode "Move to SomDay/Maybe List?")
                (actionNode "Move to Reference?")
            )
            (actionNode "Trash it ?")
        )


test : Maybe Tracker
test =
    createTracker rootNode
        |> tapLog "start"
        |> onNo
        ?|> tapLog "no"
        ?+> onYes
        ?|> tapLog "yes"
        ?+> onNo
        ?|> tapLog "no"


tapLog str val =
    let
        _ =
            val |> (Tuple.first >> Debug.log str)
    in
        val



-- view
