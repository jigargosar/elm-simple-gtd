port module Todo.Main exposing (..)

import Document
import EditMode
import Entity
import Ext.Record as Record exposing (set)
import Model
import Notification
import Return
import Todo
import Todo.Msg exposing (Msg(..))
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker as Tracker


port showTodoReminderNotification : Model.TodoNotification -> Cmd msg


port notificationClicked : (Model.TodoNotificationEvent -> msg) -> Sub msg


port showRunningTodoNotification : Notification.Request -> Cmd msg


port onRunningTodoNotificationClicked : (Notification.Response -> msg) -> Sub msg


timeTracker =
    Record.init .timeTracker (\s b -> { b | timeTracker = s })


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
        [ notificationClicked Model.OnNotificationClicked
        , onRunningTodoNotificationClicked Model.onRunningTodoNotificationClicked
        ]


update andThenUpdate now todoMsg =
    case todoMsg of
        OnEditReminderMenuStateChanged form menuState ->
            map
                (Model.setEditMode
                    (Todo.ReminderForm.setMenuState menuState form
                        |> EditMode.EditTodoReminder
                    )
                )

        ToggleRunning todoId ->
            mapOver timeTracker (Tracker.toggleStartStop todoId now)

        InitRunning todoId ->
            mapSet timeTracker (Tracker.initRunning todoId now)

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
                        shouldDisableTracker =
                            Todo.isNotActive todo
                                || Tracker.isTrackingTodo todo model.timeTracker
                    in
                        if shouldDisableTracker then
                            set timeTracker Tracker.none model
                        else
                            model
                )

        RunningNotificationResponse res ->
            let
                todoId =
                    res.data.id
            in
                (case res.action of
                    "stop" ->
                        andThenUpdate Model.onTodoStopRunning

                    _ ->
                        andThenUpdate Model.onGotoRunningTodo
                )
                    >> andThenUpdate (Model.OnCloseNotification todoId)


showRunningNotificationCmd ( maybeTrackerInfo, model ) =
    let
        createRequest info todo =
            let
                todoId =
                    Document.getId todo
            in
                { tag = todoId
                , title = "You are currently working on"
                , body = Todo.getText todo
                , actions =
                    [ { title = "Stop", action = "stop" }
                    , { title = "Mark Done", action = "mark-done" }
                    ]
                , data = { id = todoId, notificationClickedPort = "onRunningTodoNotificationClicked" }
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
                            Entity.TodoEntity doc ->
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
