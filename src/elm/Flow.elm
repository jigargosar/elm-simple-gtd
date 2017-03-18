module Flow exposing (..)

import DebugExtra.Debug exposing (tapLog)
import Flow.Model as Model exposing (Model)
import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


--rootNode =
--    Model.branchNode "Is it Actionable ?"
--        (Model.branchNode "Can be done under 2 mins?"
--            (Model.confirmActionNode "Do it now?"
--                (Model.actionNode "Timer Started, Go Go Go !!!")
--            )
--            (Model.actionNode "Involves Multiple Steps?")
--        )
--        (Model.branchNode "Is it worth keeping?"
--            (Model.branchNode "Could Require actionNode Later ?"
--                (Model.actionNode "Move to SomDay/Maybe List?")
--                (Model.actionNode "Move to Reference?")
--            )
--            (Model.actionNode "Trash it ?")
--        )
--
--
--testModel : Maybe (Model msg)
--testModel =
--    Model.init rootNode
--        |> logNode "start"
--        |> Model.onNo
--        ?|> logNode "no"
--        ?+> Model.onNo
--        ?|> logNode "no"
--
--        ?+> Model.onYes
--        ?|> logNode "yes"


logNode =
    tapLog (Model.getQuestion)


type alias Model msg =
    Model.Model msg


init =
    Model.init


branch =
    Model.branchNode


confirmAction =
    Model.confirmActionNode


action =
    Model.actionNode


update =
    Model.update

type alias FlowActionType = Model.FlowAction

getQuestion = Model.getQuestion

getNextActions = Model.getNextActions
