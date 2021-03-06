module Todo.ReminderOverlay.Model exposing (..)

import Data.TodoDoc exposing (..)
import Date
import Date.Extra as Date
import Document
import Time exposing (Time)
import Todo.ReminderOverlay.Types exposing (..)
import X.Function exposing (..)


type Action
    = ShowSnoozeOptions
    | SnoozeTill SnoozeOffset
    | Dismiss
    | MarkDone
    | Close


type SnoozeOffset
    = SnoozeForMilli Time
    | SnoozeTillTomorrow


addSnoozeOffset time offset =
    case offset of
        SnoozeForMilli milli ->
            time + milli

        SnoozeTillTomorrow ->
            Date.fromTime time |> Date.ceiling Date.Day |> Date.add Date.Hour 10 |> Date.toTime


initialView : TodoDoc -> TodoReminderOverlayModel
initialView =
    createTodoDetails >> tuple2 InitialView >> Just


createTodoDetails todo =
    TodoDetails (Document.getId todo) (Data.TodoDoc.getText todo)


none =
    Nothing


snoozeView : TodoDetails -> TodoReminderOverlayModel
snoozeView =
    tuple2 SnoozeView >> Just
