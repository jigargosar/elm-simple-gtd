module Todo.Notification.Types exposing (..)

import Document.Types exposing (DocId)
import Todo.Types exposing (TodoText)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : TodoText }


type alias InnerModel =
    ( ActiveView, TodoDetails )


type alias TodoReminderOverlayModel =
    Maybe ( ActiveView, TodoDetails )
