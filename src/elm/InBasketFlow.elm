module InBasketFlow exposing (..)

import DebugExtra.Debug exposing (tapLog)
import InBasketFlow.Model exposing (..)
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



--test : Maybe Tracker
--test =
--    init rootNode
--        |> onNo
--        ?+> onYes
--        ?+> onNo


logNode =
    tapLog (InBasketFlow.Model.getQuestion)
