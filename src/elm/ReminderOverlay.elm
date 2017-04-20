module ReminderOverlay exposing (..)

import Document
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type ActiveView
    = InitialView
    | SnoozeView


type alias TodoDetails =
    { id : Todo.Id, text : Todo.Text }


type Model
    = None
    | Active ActiveView TodoDetails


type Action
    = Snooze
    | Dismiss
    | Done


init : Todo.Model -> Model
init =
    createTodoDetails >> Active InitialView


createTodoDetails todo =
    TodoDetails (Document.getId todo) (Todo.getText todo)


none =
    None


snoozeView : TodoDetails -> Model
snoozeView =
    Active SnoozeView
