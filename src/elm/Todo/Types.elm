module Todo.Types exposing (..)

import Document.Types exposing (DocId)
import Time exposing (Time)


type alias Text =
    String


type alias Record =
    { done : Bool
    , text : Text
    , schedule : Schedule
    , projectId : DocId
    , contextId : DocId
    }


type alias Model =
    Document.Types.Document Record


type Schedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled
