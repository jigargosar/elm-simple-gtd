module Todo.Notification.Model exposing (..)

import Date
import Date.Extra as Date
import Document
import Todo
import Time exposing (Time)
import Types


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : Types.DocId__, text : Todo.Text }


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


initialView : Todo.Model -> Model
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
