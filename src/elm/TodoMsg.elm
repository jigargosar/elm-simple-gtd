module TodoMsg exposing (..)

import Msg exposing (AppMsg(OnTodoMsg))
import Todo.FormTypes exposing (..)
import Todo.Msg exposing (TodoMsg(..))
import Todo.Types exposing (TodoAction(..))


--onStopRunningTodoMsg : AppMsg


onStopRunningTodoMsg =
    OnStopRunningTodo |> OnTodoMsg



--onGotoRunningTodo : AppMsg


onGotoRunningTodoMsg =
    OnGotoRunningTodo |> OnTodoMsg



--onReminderOverlayAction : Todo.Notification.Model.Action -> AppMsg


onReminderOverlayAction =
    OnTodoReminderOverlayAction >> OnTodoMsg


onSwitchOrStartTrackingTodo todoId =
    OnSwitchOrStartTrackingTodo todoId |> OnTodoMsg



-- form add


onStartAdding__ =
    OnStartAddingTodo >> OnTodoMsg


onStartAddingTodoToInbox =
    onStartAdding__ ATFM_AddToInbox


onStartAddingTodoWithFocusInEntityAsReference =
    onStartAdding__ ATFM_AddWithFocusInEntityAsReference


onStartSetupAddTodo =
    onStartAdding__ ATFM_SetupFirstTodo



-- form edit


onStartEditing__ editMode todo =
    OnStartEditingTodo todo editMode |> OnTodoMsg


onStartEditingTodo =
    onStartEditingTodoText


onStartEditingTodoText =
    onStartEditing__ ETFM_EditTodoText


onStartEditingTodoContext =
    onStartEditing__ ETFM_EditTodoContext


onStartEditingTodoProject =
    onStartEditing__ ETFM_EditTodoProject


onStartEditingReminder =
    onStartEditing__ ETFM_EditTodoSchedule



-- form update


onUpdateFormAction__ setterAction form =
    setterAction >> OnUpdateTodoFormAction form >> OnTodoMsg


onSetTodoFormMenuState =
    onUpdateFormAction__ SetTodoMenuState


onSetTodoFormReminderDate =
    onUpdateFormAction__ SetTodoReminderDate


onSetTodoFormReminderTime =
    onUpdateFormAction__ SetTodoReminderTime


onSetTodoFormText =
    onUpdateFormAction__ SetTodoText



-- direct


onToggleDeleted id =
    Todo.Msg.UpdateTodo__ id TA_ToggleDeleted
        |> OnTodoMsg


onToggleDeletedAndMaybeSelection id =
    Todo.Msg.UpdateTodoOrAllSelected__ id TA_ToggleDeleted
        |> OnTodoMsg


onToggleDoneAndMaybeSelection id =
    Todo.Msg.UpdateTodoOrAllSelected__ id TA_ToggleDone
        |> OnTodoMsg


onSetProjectAndMaybeSelection id =
    TA_SetProject
        >> Todo.Msg.UpdateTodoOrAllSelected__ id
        >> OnTodoMsg


onSetContextAndMaybeSelection id =
    TA_SetContext
        >> Todo.Msg.UpdateTodoOrAllSelected__ id
        >> OnTodoMsg


afterTodoUpsert todo =
    Todo.Msg.AfterUpsert todo |> OnTodoMsg
