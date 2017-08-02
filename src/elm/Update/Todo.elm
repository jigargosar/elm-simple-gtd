module Update.Todo exposing (Config, update)

import Set
import Time
import Todo.Msg exposing (TodoMsg(..))
import Todo.TimeTracker as Tracker
import Update.Todo.Internal exposing (..)
import X.Function.Infix exposing (..)
import X.Return exposing (..)


type alias Config msg a =
    Update.Todo.Internal.Config msg a


update :
    Config msg a
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
            onStopRunningTodoMsg

        UpdateTimeTracker ->
            updateTimeTracker now

        AfterUpsert todo ->
            onAfterUpsertTodo todo

        OnReminderNotificationClicked notif ->
            onReminderNotificationClicked now notif

        RunningNotificationResponse res ->
            onRunningNotificationResponse config res

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
