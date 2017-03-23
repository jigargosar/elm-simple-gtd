module InboxFlow exposing (..)

import Flow
import InboxFlow.Model as Model
import Todo exposing (Todo)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


updateWithActionType =
    Model.updateWithActionType


type alias Model =
    Model.Model
