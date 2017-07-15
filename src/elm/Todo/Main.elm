port module Todo.Main exposing (..)

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
import Todo.Msg exposing (TodoMsg(..))
import Todo.Notification.Model
import Todo.Notification.Types
import TodoMsg
import X.Record as Record exposing (set)
import X.Return
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
import Types exposing (ModelF, ReturnF)
import X.Function exposing (applyMaybeWith)
import XMMsg


port showTodoReminderNotification : Notification.TodoNotification -> Cmd msg


port notificationClicked : (Notification.TodoNotificationEvent -> msg) -> Sub msg


port showRunningTodoNotification : Notification.Request -> Cmd msg


port onRunningTodoNotificationClicked : (Notification.Response -> msg) -> Sub msg


timeTracker =
    Record.fieldLens .timeTracker (\s b -> { b | timeTracker = s })


mapOver =
    Record.over >>> Return.map


mapSet =
    Record.set >>> Return.map


map =
    Return.map


command =
    Return.command


andThen =
    Return.andThen


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


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
            map
                (\model ->
                    let
                        isTrackerTodoInactive =
                            Todo.isInActive todo
                                && Tracker.isTrackingTodo todo model.timeTracker
                    in
                        if isTrackerTodoInactive then
                            set timeTracker Tracker.none model
                        else
                            model
                )

        OnReminderNotificationClicked { action, data } ->
            let
                todoId =
                    data.id
            in
                if action == "mark-done" then
                    Return.andThen (Stores.updateTodo TA_MarkDone todoId)
                        >> command (Notification.closeNotification todoId)
                else
                    todoId
                        |> ShowReminderOverlayForTodoId
                        >> Msg.OnTodoMsg
                        >> andThenUpdate

        ShowReminderOverlayForTodoId todoId ->
            Return.map (showReminderOverlayForTodoId todoId)

        RunningNotificationResponse res ->
            let
                todoId =
                    res.data.id
            in
                (case res.action of
                    "stop" ->
                        andThenUpdate TodoMsg.onStopRunningTodo

                    "continue" ->
                        identity

                    _ ->
                        andThenUpdate TodoMsg.onGotoRunningTodo
                )
                    >> andThenUpdate (Msg.OnCloseNotification todoId)

        OnProcessPendingNotificationCronTick ->
            X.Return.andThenMaybe
                (Stores.findAndSnoozeOverDueTodo >>? Return.andThen showReminderNotificationCmd)

        OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId action ->
            (Stores.updateTodoAndMaybeAlsoSelected action todoId |> andThen)
                -- todo: if we had use save editing form, we would't missed calling on deactivate.
                -- todo: also it seems an appropriate place for any exclusive mode form saves.
                -- such direct calls are messy. :(
                >> andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction action

        OnStartAddingTodo addFormMode ->
            -- todo: think about merging 4 messages into one.
            let
                createXM model =
                    Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
            in
                X.Return.returnWith createXM (XMMsg.onSetExclusiveMode >> andThenUpdate)
                    >> autoFocusInputRCmd

        OnStartEditingTodo todo editFormMode ->
            let
                createXM model =
                    Todo.Form.createEditTodoForm editFormMode model.now todo |> XMTodoForm

                positionPopup idPrefix =
                    DomPorts.positionPopupMenu (idPrefix ++ getDocId todo)
            in
                X.Return.returnWith createXM (XMMsg.onSetExclusiveMode >> andThenUpdate)
                    >> command
                        (case editFormMode of
                            ETFM_EditTodoText ->
                                autoFocusInputCmd

                            ETFM_EditTodoContext ->
                                positionPopup "#edit-context-button-"

                            ETFM_EditTodoProject ->
                                positionPopup "#edit-project-button-"

                            ETFM_EditTodoReminder ->
                                positionPopup "#edit-schedule-button-"
                        )

        OnUpdateTodoFormAction form action ->
            let
                xm =
                    Todo.Form.updateTodoForm action form |> XMTodoForm
            in
                andThenUpdate (XMMsg.onSetExclusiveMode xm)
                    >> Return.command
                        (case action of
                            Todo.FormTypes.SetTodoMenuState _ ->
                                autoFocusInputCmd

                            _ ->
                                Cmd.none
                        )


showReminderNotificationCmd ( todo, model ) =
    let
        createNotification =
            let
                id =
                    Document.getId todo
            in
                { title = Todo.getText todo, tag = id, data = { id = id } }

        cmds =
            [ createNotification
                |> showTodoReminderNotification
            , Notification.startAlarm ()
            ]
    in
        model ! cmds


showRunningNotificationCmd ( maybeTrackerInfo, model ) =
    let
        createRequest info todo =
            let
                todoId =
                    Document.getId todo

                formattedDuration =
                    X.Time.toHHMMSSMin (info.elapsedTime)
            in
                { tag = todoId
                , title = "You have been working for " ++ formattedDuration
                , body = Todo.getText todo
                , actions =
                    [ { title = "Continue", action = "continue" }
                    , { title = "Stop", action = "stop" }
                    ]
                , data =
                    { id = todoId
                    , notificationClickedPort = "onRunningTodoNotificationClicked"
                    , skipFocusActionList = [ "continue" ]
                    }
                }
    in
        maybeTrackerInfo
            ?+> (\info -> Stores.findTodoById info.todoId model ?|> createRequest info)
            |> maybeMapToCmd showRunningTodoNotification


updateTimeTracker now =
    Record.overT2 timeTracker (Tracker.updateNextAlarmAt now)
        >> apply2 ( Tuple.second, showRunningNotificationCmd )
        |> andThen


gotoRunningTodo model =
    Tracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithIdIn model
        ?= model


gotoTodoWithIdIn =
    flip gotoTodoWithId


gotoTodoWithId todoId model =
    let
        maybeTodoEntity =
            Stores.getCurrentViewEntityList model
                |> List.find
                    (\entity ->
                        case entity of
                            Entity.Types.TodoEntity doc ->
                                Document.hasId todoId doc

                            _ ->
                                False
                    )
    in
        maybeTodoEntity
            |> Maybe.unpack
                (\_ ->
                    model
                        |> Stores.setFocusInEntityWithTodoId todoId
                        |> Model.ViewType.switchToContextsView
                )
                (Stores.setFocusInEntity # model)


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.Notification.Model.initialView todo }


inboxEntity =
    Entity.Types.createContextEntity Context.null


reminderOverlayAction action =
    Return.andThen
        (\model ->
            model
                |> case model.reminderOverlay of
                    Todo.Notification.Types.Active activeView todoDetails ->
                        let
                            todoId =
                                todoDetails.id
                        in
                            case action of
                                Todo.Notification.Model.Dismiss ->
                                    Stores.updateTodo (TA_TurnReminderOff) todoId
                                        >> Tuple.mapFirst removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.ShowSnoozeOptions ->
                                    setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                Todo.Notification.Model.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.andThen (snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.Close ->
                                    removeReminderOverlay
                                        >> Return.singleton

                                Todo.Notification.Model.MarkDone ->
                                    Stores.updateTodo TA_MarkDone todoId
                                        >> Tuple.mapFirst removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                    _ ->
                        Return.singleton
        )


snoozeTodoWithOffset snoozeOffset todoId model =
    let
        time =
            Todo.Notification.Model.addSnoozeOffset model.now snoozeOffset
    in
        model
            |> Stores.updateTodo (time |> TA_SnoozeTill) todoId
            >> Tuple.mapFirst removeReminderOverlay


removeReminderOverlay model =
    { model | reminderOverlay = Todo.Notification.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.Notification.Model.snoozeView details }
