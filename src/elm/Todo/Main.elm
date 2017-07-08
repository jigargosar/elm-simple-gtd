port module Todo.Main exposing (..)

import Document
import DomPorts
import Entity.Types
import ExclusiveMode
import Entity
import Msg
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
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * 1) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30) (\_ -> OnProcessPendingNotificationCronTick)
        ]
        |> Sub.map Msg.OnTodoMsg


update :
    (Msg.Msg -> Model.ReturnF)
    -> Time.Time
    -> Msg
    -> Model.ReturnF
update andThenUpdate now todoMsg =
    case todoMsg of
        UpdateSetupFormTodoText form todoText ->
            Return.map
                (Todo.NewForm.setText todoText form
                    |> ExclusiveMode.Setup
                    |> Model.setEditMode
                )

        OnShowMoreMenu todoId ->
            Return.map (ExclusiveMode.todoMoreMenu todoId |> Model.setEditMode)
                >> Return.command (positionMoreMenuCmd todoId)

        UpdateReminderForm form action ->
            Return.map
                (Todo.ReminderForm.update action form
                    |> ExclusiveMode.EditTodoReminder
                    >> Model.setEditMode
                )

        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        SwitchOrStartRunning todoId ->
            mapOver timeTracker (Tracker.switchOrStartRunning todoId now)

        StopRunning ->
            mapSet timeTracker Tracker.none

        GotoRunning ->
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
                    Return.andThen (Model.updateTodo Todo.MarkDone todoId)
                        >> command (Notification.closeNotification todoId)
                else
                    todoId
                        |> ShowReminderOverlayForTodoId
                        >> Msg.OnTodoMsg
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
                    >> andThenUpdate (Msg.OnCloseNotification todoId)

        OnProcessPendingNotificationCronTick ->
            X.Return.andThenMaybe
                (Model.findAndSnoozeOverDueTodo >>? Return.andThen showReminderNotificationCmd)

        OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode todoId action ->
            (Model.updateTodoAndMaybeAlsoSelected action todoId |> andThen)
                -- todo: if we had use save editing form, we would't missed calling on deactivate.
                -- todo: also it seems an appropriate place for any exclusive mode form saves.
                -- such direct calls are messy. :(
                >> andThenUpdate Msg.OnDeactivateEditingMode


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
                            Entity.Types.Todo doc ->
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


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)
