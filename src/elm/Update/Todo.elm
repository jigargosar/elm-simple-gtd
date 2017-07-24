module Update.Todo exposing (Config, update)

import Return
import Set
import Time
import Todo.Msg exposing (TodoMsg(..))
import Todo.TimeTracker as Tracker
import Update.Todo.Internal exposing (..)
import X.Function.Infix exposing (..)
import X.Return exposing (..)


type alias Config msg model =
    Update.Todo.Internal.Config msg model


update :
    Config msg model
    -> Time.Time
    -> TodoMsg
    -> SubReturnF msg model
update config now msg =
    case msg of
        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        OnSwitchOrStartTrackingTodo todoId ->
            mapOver timeTracker (Tracker.switchOrStartRunning todoId now)

        OnStopRunningTodo ->
            onStopRunningTodo

        OnGotoRunningTodo ->
            onGotoRunningTodo config

        UpdateTimeTracker ->
            updateTimeTracker now

        AfterUpsert todo ->
            onAfterUpsertTodo todo

        OnReminderNotificationClicked notif ->
            onReminderNotificationClicked notif

        RunningNotificationResponse res ->
            onRunningNotificationResponse config res

        OnProcessPendingNotificationCronTick ->
            rAndThenMaybe
                (findAndSnoozeOverDueTodo >>? andThen showReminderNotificationCmd)

        UpdateTodoOrAllSelected__ todoId action ->
            (updateTodoAndMaybeAlsoSelected action todoId |> andThen)
                >> config.afterTodoUpdate

        UpdateTodo__ todoId action ->
            (updateAllTodos action (Set.singleton todoId) |> andThen)
                >> config.afterTodoUpdate

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction action

        OnStartAddingTodo addFormMode ->
            onStartAddingTodo config addFormMode

        OnStartEditingTodo todo editFormMode ->
            onStartEditingTodo config todo editFormMode

        OnUpdateTodoFormAction form action ->
            onUpdateTodoFormAction config form action

        OnSaveTodoForm form ->
            onSaveTodoForm config form
