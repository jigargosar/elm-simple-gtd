module InboxFlow exposing (..)

import Flow
import InboxFlow.Model as Model
import Main.Msg exposing (Msg(OnFlowTrashItClicked))
import Todo exposing (Todo)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


init todoList =
    Model.modelConstructor todoList


updateWithActionType =
    Model.updateWithActionType


type alias Model =
    Model.Model
