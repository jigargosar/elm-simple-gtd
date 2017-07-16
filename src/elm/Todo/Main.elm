module Todo.Main exposing (..)

import Context
import Document
import Document.Types exposing (getDocId)
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd)
import Entity.Types
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import Model.ViewType
import Msg
import Stores exposing (findTodoById)
import Todo.Form
import Todo.FormTypes exposing (EditTodoFormMode(..))
import Todo.MainHelp exposing (..)
import Todo.MainHelpPort exposing (..)
import Todo.Msg exposing (TodoMsg(..))
import Todo.Notification.Model
import Todo.Notification.Types
import TodoMsg
import X.Record as Record exposing (set)
import X.Return exposing (rAndThenMaybe)
import X.Time
import Model
import Notification
import Return
import Time
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker as Tracker
import Todo.Types exposing (TodoAction(TA_MarkDone, TA_SnoozeTill, TA_TurnReminderOff))
import ReturnTypes exposing (..)
import X.Function exposing (applyMaybeWith)
import XMMsg


subscriptions m =
    Sub.batch
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * 1) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30) (\_ -> OnProcessPendingNotificationCronTick)
        ]
        |> Sub.map Msg.OnTodoMsg


update :
    (Msg.AppMsg -> ReturnF)
    -> Time.Time
    -> TodoMsg
    -> ReturnF
update andThenUpdate now todoMsg =
    case todoMsg of
        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        SwitchOrStartRunning todoId ->
            mapOver timeTracker (Tracker.switchOrStartRunning todoId now)

        OnStopRunningTodo ->
            mapSet timeTracker Tracker.none

        OnGotoRunningTodo ->
            map (gotoRunningTodo)
                >> andThenUpdate Model.setDomFocusToFocusInEntityCmd

        UpdateTimeTracker ->
            updateTimeTracker now

        Upsert todo ->
            onUpsertTodo todo

        OnReminderNotificationClicked notif ->
            onReminderNotificationClicked andThenUpdate notif

        ShowReminderOverlayForTodoId todoId ->
            map (showReminderOverlayForTodoId todoId)

        RunningNotificationResponse res ->
            onRunningNotificationResponse andThenUpdate res

        OnProcessPendingNotificationCronTick ->
            rAndThenMaybe
                (Stores.findAndSnoozeOverDueTodo >>? andThen showReminderNotificationCmd)

        OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId action ->
            (Stores.updateTodoAndMaybeAlsoSelected action todoId |> andThen)
                -- todo: if we had use save editing form, we would't missed calling on deactivate.
                -- todo: also it seems an appropriate place for any exclusive mode form saves.
                -- such direct calls are messy. :(
                >> andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction action

        OnStartAddingTodo addFormMode ->
            onStartAddingTodo andThenUpdate addFormMode

        OnStartEditingTodo todo editFormMode ->
            onStartEditingTodo andThenUpdate todo editFormMode

        OnUpdateTodoFormAction form action ->
            onUpdateTodoFormAction andThenUpdate form action
