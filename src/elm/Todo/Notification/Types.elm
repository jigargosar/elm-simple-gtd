module Todo.Notification.Types exposing (..)

import Document.Types exposing (DocId)
import Todo.Types exposing (TodoText)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : TodoText }


type TodoReminderOverlayModel
    = None
    | Active ActiveView TodoDetails
