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



-- start add


onStartAddingTodoToInbox =
    OnStartAddingTodo ATFM_AddToInbox |> OnTodoMsg


onStartAddingTodoWithFocusInEntityAsReference =
    OnStartAddingTodo ATFM_AddWithFocusInEntityAsReference |> OnTodoMsg


onStartSetupAddTodo =
    OnStartAddingTodo ATFM_SetupFirstTodo |> OnTodoMsg



-- start edit


onStartEditing editMode todo =
    OnStartEditingTodo todo editMode |> OnTodoMsg


onStartEditingTodo =
    onStartEditingTodoText


onStartEditingTodoText =
    onStartEditing ETFM_EditTodoText


onStartEditingTodoContext =
    onStartEditing ETFM_EditTodoContext


onStartEditingTodoProject =
    onStartEditing ETFM_EditTodoProject


onStartEditingReminder =
    onStartEditing ETFM_EditTodoReminder



-- update


onUpdateFormAction setterAction form =
    setterAction >> OnUpdateTodoFormAction form >> OnTodoMsg


onSetTodoFormMenuState =
    onUpdateFormAction SetTodoMenuState


onSetTodoFormReminderDate =
    onUpdateFormAction SetTodoReminderDate


onSetTodoFormReminderTime =
    onUpdateFormAction SetTodoReminderTime


onSetTodoFormText =
    onUpdateFormAction SetTodoText
