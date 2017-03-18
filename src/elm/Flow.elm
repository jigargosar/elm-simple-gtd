module Flow exposing (..)

import DebugExtra.Debug exposing (tapLog)
import Flow.Model as Model exposing (Model)
import List.Extra
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


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
