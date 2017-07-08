module Todo.Types exposing (..)

import Document.Types exposing (DocId)
import Time exposing (Time)


type alias TodoText =
    String


type alias Record =
    { done : Bool
    , text : TodoText
    , schedule : Schedule
    , projectId : DocId
    , contextId : DocId
    }


type alias TodoDoc =
    Document.Types.Document Record


type Schedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled
