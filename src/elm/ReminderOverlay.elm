module ReminderOverlay exposing (..)

import Date
import Date.Extra as Date
import Date.Extra.TimeUnit exposing (TimeUnit)
import Document
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : Todo.Id, text : Todo.Text }


type Model
    = None
    | Active ActiveView TodoDetails


type Action
    = ShowSnoozeOptions
    | SnoozeTill SnoozeOffset
    | Dismiss
    | MarkDone


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
