module TodoMsg exposing (onStopRunningTodo, onGotoRunningTodo, onReminderOverlayAction, onNewTodoForInbox)

import Msg exposing (Msg(OnTodoMsg))
import Todo.Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.Notification.Model


onStopRunningTodo : Msg
onStopRunningTodo =
    Todo.Msg.StopRunning |> OnTodoMsg


onGotoRunningTodo : Msg
onGotoRunningTodo =
    Todo.Msg.GotoRunning |> OnTodoMsg


onReminderOverlayAction : Todo.Notification.Model.Action -> Msg
onReminderOverlayAction =
    Todo.Msg.OnReminderOverlayAction >> OnTodoMsg


onNewTodoForInbox : Msg
onNewTodoForInbox =
    Todo.Msg.OnNewTodoForInbox |> OnTodoMsg
