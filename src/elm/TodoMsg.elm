module TodoMsg exposing (..)

import Msg exposing (AppMsg(OnTodoMsg))
import Todo.FormTypes exposing (..)
import Todo.Msg exposing (TodoMsg(..))
import Todo.Notification.Model
import X.Function.Infix exposing (..)


onStopRunningTodo : AppMsg
onStopRunningTodo =
    OnStopRunningTodo |> OnTodoMsg


onGotoRunningTodo : AppMsg
onGotoRunningTodo =
    OnGotoRunningTodo |> OnTodoMsg


onReminderOverlayAction : Todo.Notification.Model.Action -> AppMsg
onReminderOverlayAction =
    OnTodoReminderOverlayAction >> OnTodoMsg


onStartEditingTodo =
    onStartEditingTodoText


createStartEditingTodoMsg editMode todo =
    OnStartEditingTodo todo editMode |> OnTodoMsg


onStartEditingTodoText =
    createStartEditingTodoMsg ETFM_EditTodoText


onStartEditingTodoContext =
    createStartEditingTodoMsg ETFM_EditTodoContext


onStartEditingTodoProject =
    createStartEditingTodoMsg ETFM_EditTodoProject


onStartEditingReminder =
    createStartEditingTodoMsg ETFM_EditTodoReminder


onSetTodoFormMenuState form =
    SetTodoMenuState >> OnUpdateTodoForm form >> OnTodoMsg


onSetTodoFormReminderDate form =
    SetTodoReminderDate >> OnUpdateTodoForm form >> OnTodoMsg


onSetTodoFormReminderTime form =
    SetTodoReminderTime >> OnUpdateTodoForm form >> OnTodoMsg


onSetTodoFormText form =
    SetTodoText >> OnUpdateTodoForm form >> OnTodoMsg


onStartAddingTodoToInbox =
    OnStartAddingTodo ATFM_AddToInbox |> OnTodoMsg


onStartAddingTodoWithFocusInEntityAsReference =
    OnStartAddingTodo ATFM_AddWithFocusInEntityAsReference |> OnTodoMsg


onStartSetupAddTodo =
    OnStartAddingTodo ATFM_SetupFirstTodo |> OnTodoMsg
