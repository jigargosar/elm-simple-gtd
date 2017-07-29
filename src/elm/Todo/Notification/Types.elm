module Todo.Notification.Types exposing (..)

import Todo.Types exposing (TodoText)
import Types.Document exposing (..)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : TodoText }


type alias InnerModel =
    ( ActiveView, TodoDetails )


type alias TodoReminderOverlayModel =
    Maybe ( ActiveView, TodoDetails )
