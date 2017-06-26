port module Task.Main exposing (..)

import Document
import DomPorts
import ExclusiveMode
import Entity
import Todo.NewForm
import X.Record as Record exposing (set)
import X.Return
import X.Time
import Model
import Notification
import Return
import Time
import Todo
import Todo.Msg exposing (Msg(..))
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker as Tracker


port showTodoReminderNotification : Notification.TodoNotification -> Cmd msg


port notificationClicked : (Notification.TodoNotificationEvent -> msg) -> Sub msg


port showRunningTodoNotification : Notification.Request -> Cmd msg


port onRunningTodoNotificationClicked : (Notification.Response -> msg) -> Sub msg


timeTracker =
    Record.field .timeTracker (\s b -> { b | timeTracker = s })


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
        [ notificationClicked (Todo.Msg.OnReminderNotificationClicked >> Model.OnTaskMsg)
        , onRunningTodoNotificationClicked (Todo.Msg.RunningNotificationResponse >> Model.OnTaskMsg)
        , Time.every (Time.second * 1) (Model.OnTaskMsgWithTime Todo.Msg.UpdateTimeTracker)
        , Time.every (Time.second * 30)
            (\_ -> Model.OnTaskMsg Todo.Msg.OnProcessPendingNotificationCronTick)
        ]


update :
    (Model.Msg -> Model.ReturnF)
    -> Time.Time
    -> Todo.Msg.Msg
    -> Model.ReturnF
update andThenUpdate now todoMsg =
    case todoMsg of
        UpdateSetupFormTaskText form taskText ->
            Return.map
                (Todo.NewForm.setText taskText form
                    |> ExclusiveMode.Setup
                    |> Model.setEditMode
                )

        OnShowMoreMenu taskId ->
            Return.map (ExclusiveMode.taskMoreMenu taskId |> Model.setEditMode)
                >> Return.command (positionMoreMenuCmd taskId)

        UpdateReminderForm form action ->
            Return.map
                (Todo.ReminderForm.update action form
                    |> ExclusiveMode.EditTodoReminder
                    >> Model.setEditMode
                )

        --                >> DomPorts.autoFocusInputCmd
        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        InitRunning todoId ->
            mapSet timeTracker (Tracker.initRunning todoId now)

        SwitchOrStartRunning todoId ->
            mapOver timeTracker (Tracker.switchOrStartRunning todoId now)

        TogglePaused ->
            mapOver timeTracker (Tracker.togglePause now)

        StopRunning ->
            mapSet timeTracker Tracker.none

        GotoRunning ->
            map (gotoRunningTodo)
                >> andThenUpdate Model.OnSetDomFocusToFocusInEntity

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
                    Return.andThen (Model.updateTodo Todo.MarkDone todoId)
                        >> command (Notification.closeNotification todoId)
                else
                    todoId
                        |> Todo.Msg.ShowReminderOverlayForTodoId
                        >> Model.OnTaskMsg
                        >> andThenUpdate

        ShowReminderOverlayForTodoId todoId ->
            Return.map (Model.showReminderOverlayForTodoId todoId)

        RunningNotificationResponse res ->
            let
                todoId =
                    res.data.id
            in
                (case res.action of
                    "stop" ->
                        andThenUpdate Model.onTodoStopRunning

                    "continue" ->
                        identity

                    _ ->
                        andThenUpdate Model.onGotoRunningTodo
                )
                    >> andThenUpdate (Model.OnCloseNotification todoId)

        OnProcessPendingNotificationCronTick ->
            X.Return.andThenMaybe
                (Model.findAndSnoozeOverDueTodo >>? Return.andThen showReminderNotificationCmd)


showReminderNotificationCmd ( task, model ) =
    let
        createNotification =
            let
                id =
                    Document.getId task
            in
                { title = Todo.getText task, tag = id, data = { id = id } }

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
            ?+> (\info -> Model.findTodoById info.todoId model ?|> createRequest info)
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
            Model.getCurrentViewEntityList model
                |> List.find
                    (\entity ->
                        case entity of
                            Entity.Task doc ->
                                Document.hasId todoId doc

                            _ ->
                                False
                    )
    in
        maybeTodoEntity
            |> Maybe.unpack
                (\_ ->
                    model
                        |> Model.setFocusInEntityFromTodoId todoId
                        |> Model.switchToContextsView
                )
                (Model.setFocusInEntity # model)


positionMoreMenuCmd taskId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ taskId)
