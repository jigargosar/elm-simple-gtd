module Update.Todo exposing (..)

import Document exposing (..)
import Notification exposing (Response)
import Todo.FormTypes exposing (..)
import Todo.Notification.Model
import TodoDoc exposing (..)


type TodoMsg
    = OnReminderNotificationClicked Notification.TodoNotificationEvent
    | OnProcessPendingNotificationCronTick
    | UpdateTodoOrAllSelected__ DocId TodoAction
    | UpdateTodo__ DocId TodoAction
    | OnTodoReminderOverlayAction Todo.Notification.Model.Action
    | OnStartAddingTodo AddTodoFormMode
    | OnStartEditingTodo TodoDoc EditTodoFormMode
    | OnUpdateTodoFormAction TodoForm TodoFormAction
    | OnSaveTodoForm TodoForm


onReminderOverlayAction =
    OnTodoReminderOverlayAction



-- form add


onStartAdding__ =
    OnStartAddingTodo


onStartAddingTodoToInbox =
    onStartAdding__ ATFM_AddToInbox


onStartAddingTodoWithFocusInEntityAsReference =
    ATFM_AddWithFocusInEntityAsReference >> onStartAdding__


onStartSetupAddTodo =
    onStartAdding__ ATFM_SetupFirstTodo



-- form edit


onStartEditing__ editMode todo =
    OnStartEditingTodo todo editMode


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
    setterAction >> OnUpdateTodoFormAction form


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
    UpdateTodo__ id TA_ToggleDeleted


onToggleDeletedAndMaybeSelection id =
    UpdateTodoOrAllSelected__ id TA_ToggleDeleted


onToggleDoneAndMaybeSelection id =
    UpdateTodoOrAllSelected__ id TA_ToggleDone


onSetProjectAndMaybeSelection id =
    TA_SetProject
        >> UpdateTodoOrAllSelected__ id


onSetContextAndMaybeSelection id =
    TA_SetContext
        >> UpdateTodoOrAllSelected__ id
