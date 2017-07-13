module TodoMsg exposing (..)

import Msg exposing (Msg(OnTodoMsg))
import Todo.FormTypes exposing (..)
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


onStartEditingTodoText todo =
    Msg.OnStartEditingTodo todo XMEditTodoText


onStartEditingTodoContext todo =
    Msg.OnStartEditingTodo todo XMEditTodoContext


onStartEditingTodoProject todo =
    Msg.OnStartEditingTodo todo XMEditTodoProject


onStartEditingReminder todo =
    Msg.OnStartEditingTodo todo XMEditTodoReminder


onSetTodoFormMenuState form =
    SetTodoMenuState >> Msg.OnUpdateEditTodoForm form


onSetTodoFormReminderDate form =
    SetTodoReminderDate >> Msg.OnUpdateEditTodoForm form


onSetTodoFormReminderTime form =
    SetTodoReminderTime >> Msg.OnUpdateEditTodoForm form


onSetTodoFormText form =
    SetTodoText >> Msg.OnUpdateEditTodoForm form
