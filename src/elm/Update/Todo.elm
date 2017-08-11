module Update.Todo exposing (..)

import Data.TodoDoc exposing (..)
import Document exposing (..)
import Notification exposing (Response)
import Set
import Time
import Todo.FormTypes exposing (..)
import Todo.ReminderOverlay.Model
import Update.Todo.Internal exposing (..)
import X.Function.Infix exposing (..)
import X.Return exposing (..)


type TodoMsg
    = OnReminderNotificationClicked Notification.TodoNotificationEvent
    | OnProcessPendingNotificationCronTick
    | UpdateTodoOrAllSelected__ DocId TodoAction
    | UpdateTodo__ DocId TodoAction
    | OnTodoReminderOverlayAction Todo.ReminderOverlay.Model.Action
    | OnStartAddingTodo AddTodoFormMode
    | OnStartEditingTodo TodoDoc EditTodoFormMode
    | OnUpdateTodoFormAction TodoForm TodoFormAction
    | OnSaveTodoForm TodoForm


onReminderOverlayActionMsg =
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


onStartEditingMsg__ editMode todo =
    OnStartEditingTodo todo editMode


onStartEditingTodoMsg =
    onStartEditingTodoTextMsg


onStartEditingTodoTextMsg =
    onStartEditingMsg__ ETFM_EditTodoText


onStartEditingTodoContextMsg =
    onStartEditingMsg__ ETFM_EditTodoContext


onStartEditingTodoProjectMsg =
    onStartEditingMsg__ ETFM_EditTodoProject


onStartEditingReminderMsg =
    onStartEditingMsg__ ETFM_EditTodoSchedule



-- form update


onUpdateFormActionMsg__ setterAction form =
    setterAction >> OnUpdateTodoFormAction form


onSetTodoFormMenuStateMsg =
    onUpdateFormActionMsg__ SetTodoMenuState


onSetTodoFormReminderDateMsg =
    onUpdateFormActionMsg__ SetTodoReminderDate


onSetTodoFormReminderTimeMsg =
    onUpdateFormActionMsg__ SetTodoReminderTime


onSetTodoFormTextMsg =
    onUpdateFormActionMsg__ SetTodoText



-- direct


onToggleDeletedMsg id =
    UpdateTodo__ id TA_ToggleDeleted


onToggleDeletedAndMaybeSelectionMsg id =
    UpdateTodoOrAllSelected__ id TA_ToggleDeleted


onToggleDoneAndMaybeSelectionMsg id =
    UpdateTodoOrAllSelected__ id TA_ToggleDone


onSetProjectAndMaybeSelectionMsg id =
    TA_SetProject
        >> UpdateTodoOrAllSelected__ id


onSetContextAndMaybeSelectionMsg id =
    TA_SetContext
        >> UpdateTodoOrAllSelected__ id


type alias Config msg a =
    Update.Todo.Internal.Config msg a


update :
    Config msg a
    -> Time.Time
    -> TodoMsg
    -> SubReturnF msg model
update config now msg =
    case msg of
        OnReminderNotificationClicked notificationEvent ->
            onReminderNotificationClicked config now notificationEvent

        OnProcessPendingNotificationCronTick ->
            returnAndThenMaybe
                (findAndSnoozeOverDueTodo now >>? andThen showReminderNotificationCmd)

        UpdateTodoOrAllSelected__ todoId action ->
            (updateTodoAndMaybeAlsoSelected action now todoId |> andThen)
                >> returnMsgAsCmd config.revertExclusiveMode

        UpdateTodo__ todoId action ->
            (updateAllTodos action now (Set.singleton todoId) |> andThen)
                >> returnMsgAsCmd config.revertExclusiveMode

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction action now

        OnStartAddingTodo addFormMode ->
            onStartAddingTodo config addFormMode

        OnStartEditingTodo todo editFormMode ->
            onStartEditingTodo config now todo editFormMode

        OnUpdateTodoFormAction form action ->
            onUpdateTodoFormAction config form action

        OnSaveTodoForm form ->
            onSaveTodoForm config form now
