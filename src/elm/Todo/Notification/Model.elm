module Todo.Notification.Model exposing (..)

import Date
import Date.Extra as Date
import Document
import Todo
import Time exposing (Time)
import Todo.Notification.Types exposing (..)
import Todo.Types exposing (TodoDoc)


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
    createTodoDetails >> Active InitialView


createTodoDetails todo =
    TodoDetails (Document.getId todo) (Todo.getText todo)


none =
    None


snoozeView : TodoDetails -> TodoReminderOverlayModel
snoozeView =
    Active SnoozeView


dummy =
    Active InitialView (TodoDetails "dummy-todo-id" "dummy todo")
