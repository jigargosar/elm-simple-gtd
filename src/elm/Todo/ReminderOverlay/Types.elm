module Todo.ReminderOverlay.Types exposing (..)

import Data.TodoDoc exposing (..)
import Document exposing (..)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : TodoText }


type alias InnerModel =
    ( ActiveView, TodoDetails )


type alias TodoReminderOverlayModel =
    Maybe ( ActiveView, TodoDetails )
