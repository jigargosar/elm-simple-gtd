module TodoMsg exposing (..)

import Msg exposing (AppMsg(OnTodoMsg))
import Todo.FormTypes exposing (..)
import Todo.Msg exposing (TodoMsg(..))
import Todo.Notification.Model


onStopRunningTodo : AppMsg
onStopRunningTodo =
    OnStopRunningTodo |> Msg.OnTodoMsg


onGotoRunningTodo : AppMsg
onGotoRunningTodo =
    OnGotoRunningTodo |> Msg.OnTodoMsg


onReminderOverlayAction : Todo.Notification.Model.Action -> AppMsg
onReminderOverlayAction =
    OnTodoReminderOverlayAction >> Msg.OnTodoMsg



-- form add


onStartAdding__ =
    OnStartAddingTodo >> Msg.OnTodoMsg


onStartAddingTodoToInbox =
    onStartAdding__ ATFM_AddToInbox


onStartAddingTodoWithFocusInEntityAsReference =
    onStartAdding__ ATFM_AddWithFocusInEntityAsReference


onStartSetupAddTodo =
    onStartAdding__ ATFM_SetupFirstTodo



-- form edit


onStartEditing__ editMode todo =
    OnStartEditingTodo todo editMode |> Msg.OnTodoMsg


onStartEditingTodo =
    onStartEditingTodoText


onStartEditingTodoText =
    onStartEditing__ ETFM_EditTodoText


onStartEditingTodoContext =
    onStartEditing__ ETFM_EditTodoContext


onStartEditingTodoProject =
    onStartEditing__ ETFM_EditTodoProject


onStartEditingReminder =
    onStartEditing__ ETFM_EditTodoReminder



-- form update


onUpdateFormAction__ setterAction form =
    setterAction >> OnUpdateTodoFormAction form >> Msg.OnTodoMsg


onSetTodoFormMenuState =
    onUpdateFormAction__ SetTodoMenuState


onSetTodoFormReminderDate =
    onUpdateFormAction__ SetTodoReminderDate


onSetTodoFormReminderTime =
    onUpdateFormAction__ SetTodoReminderTime


onSetTodoFormText =
    onUpdateFormAction__ SetTodoText



--
