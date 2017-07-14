module TodoMsg exposing (..)

import Msg exposing (AppMsg(OnTodoMsg))
import Todo.FormTypes exposing (..)
import Todo.Msg
import Todo.Notification.Model


onStopRunningTodo : AppMsg
onStopRunningTodo =
    Todo.Msg.StopRunning |> OnTodoMsg


onGotoRunningTodo : AppMsg
onGotoRunningTodo =
    Todo.Msg.GotoRunning |> OnTodoMsg


onReminderOverlayAction : Todo.Notification.Model.Action -> AppMsg
onReminderOverlayAction =
    Todo.Msg.OnReminderOverlayAction >> OnTodoMsg


onStartEditingTodoText todo =
    Msg.OnStartEditingTodo todo ETFM_EditTodoText


onStartEditingTodoContext todo =
    Msg.OnStartEditingTodo todo ETFM_EditTodoContext


onStartEditingTodoProject todo =
    Msg.OnStartEditingTodo todo ETFM_XMEditTodoProject


onStartEditingReminder todo =
    Msg.OnStartEditingTodo todo ETFM_EditTodoReminder


onSetTodoFormMenuState form =
    SetTodoMenuState >> Msg.OnUpdateEditTodoForm form


onSetTodoFormReminderDate form =
    SetTodoReminderDate >> Msg.OnUpdateEditTodoForm form


onSetTodoFormReminderTime form =
    SetTodoReminderTime >> Msg.OnUpdateEditTodoForm form


onSetTodoFormText form =
    SetTodoText >> Msg.OnUpdateEditTodoForm form


onStartAddingTodoToInbox =
    Msg.OnStartAddingTodo ATFM_AddToInbox


onStartAddingTodoWithFocusInEntityAsReference =
    Msg.OnStartAddingTodo ATFM_AddWithFocusInEntityAsReference


onStartSetupAddTodo =
    Msg.OnStartAddingTodo ATFM_SetupFirstTodo


onUpdateAddTodoFormSetText =
    Msg.OnUpdateAddTodoForm
