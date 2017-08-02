module Todo.Notification.Types exposing (..)

import Document exposing (..)
import TodoDoc exposing (..)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : TodoText }


type alias InnerModel =
    ( ActiveView, TodoDetails )


type alias TodoReminderOverlayModel =
    Maybe ( ActiveView, TodoDetails )
