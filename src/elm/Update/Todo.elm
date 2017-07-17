module Update.Todo exposing (..)

import Msg
import Return exposing (andThen)
import Stores
import Todo.MainHelp exposing (..)
import Todo.MainHelpPort exposing (..)
import Todo.Msg exposing (TodoMsg(..))
import X.Return exposing (rAndThenMaybe, returnWith, returnWithMaybe2)
import Model
import Time
import X.Function.Infix exposing (..)
import Todo.TimeTracker as Tracker
import ReturnTypes exposing (..)
import XMMsg


subscriptions m =
    Sub.batch
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * 1) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30) (\_ -> OnProcessPendingNotificationCronTick)
        ]
        |> Sub.map Msg.OnTodoMsg


type alias Config =
    Todo.MainHelp.Config


update :
    Config
    -> Time.Time
    -> TodoMsg
    -> ReturnF
update config now todoMsg =
    case todoMsg of
        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        SwitchOrStartRunning todoId ->
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
                (Stores.findAndSnoozeOverDueTodo >>? andThen showReminderNotificationCmd)

        OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId action ->
            (Stores.updateTodoAndMaybeAlsoSelected action todoId |> andThen)
                -- todo: if we had use save editing form, we would't missed calling on deactivate.
                -- todo: also it seems an appropriate place for any exclusive mode form saves.
                -- such direct calls are messy. :(
                >> config.afterTodoUpdate

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction action

        OnStartAddingTodo addFormMode ->
            onStartAddingTodo config addFormMode

        OnStartEditingTodo todo editFormMode ->
            onStartEditingTodo config todo editFormMode

        OnUpdateTodoFormAction form action ->
            onUpdateTodoFormAction config form action
