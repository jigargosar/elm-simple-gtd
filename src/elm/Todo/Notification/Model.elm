module Todo.Notification.Model exposing (..)

import Date
import Date.Extra as Date
import Document
import Document.Types exposing (DocId)
import Todo
import Time exposing (Time)
import Todo.Types exposing (TodoDoc)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : DocId, text : Todo.Text }


type Model
    = None
    | Active ActiveView TodoDetails


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


initialView : TodoDoc -> Model
initialView =
    createTodoDetails >> Active InitialView


createTodoDetails todo =
    TodoDetails (Document.getId todo) (Todo.getText todo)


none =
    None


snoozeView : TodoDetails -> Model
snoozeView =
    Active SnoozeView


dummy =
    Active InitialView (TodoDetails "dummy-todo-id" "dummy todo")
