module TodoMsg exposing (..)

import Msg exposing (Msg(OnTodoMsg))
import Todo.Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


onStopRunningTodo =
    Todo.Msg.StopRunning |> OnTodoMsg


onGotoRunningTodo =
    Todo.Msg.GotoRunning |> OnTodoMsg


onReminderOverlayAction =
    Todo.Msg.OnReminderOverlayAction >> OnTodoMsg


onNewTodoForInbox =
    Todo.Msg.OnNewTodoForInbox |> OnTodoMsg
