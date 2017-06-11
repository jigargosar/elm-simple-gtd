port module Todo.Main exposing (..)

import Document
import Entity
import Ext.Record
import Model
import Notification
import Return
import Todo
import Todo.Msg exposing (Msg(..))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker


port showTodoReminderNotification : Model.TodoNotification -> Cmd msg


port notificationClicked : (Model.TodoNotificationEvent -> msg) -> Sub msg


port showRunningTodoNotification : Notification.Request -> Cmd msg


port onRunningTodoNotificationClicked : (Notification.Response -> msg) -> Sub msg


timeTracker =
    Ext.Record.init .timeTracker (\s b -> { b | timeTracker = s })


over =
    Ext.Record.over >>> Return.map


set =
    Ext.Record.set >>> Return.map


map =
    Return.map


command =
    Return.command


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


subscriptions m =
    Sub.batch
        [ notificationClicked Model.OnNotificationClicked
        , onRunningTodoNotificationClicked Model.onRunningTodoNotificationClicked
        ]


update andThenUpdate todoMsg now =
    case todoMsg of
        ToggleRunning todoId ->
            over timeTracker (Todo.TimeTracker.toggleStartStop todoId now)

        InitRunning todoId ->
            set timeTracker (Todo.TimeTracker.initRunning todoId now)

        TogglePaused ->
            over timeTracker (Todo.TimeTracker.togglePause now)

        StopRunning ->
            set timeTracker Todo.TimeTracker.none

        GotoRunning ->
            map (gotoRunningTodo)
                >> andThenUpdate Model.OnSetDomFocusToFocusInEntity

        UpdateTimeTracker ->
            let
                maybeCreateRunningTodoNotificationRequest maybeTrackerInfo model =
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

                foo ( maybeTrackerInfo, model ) =
                    ( model
                    , maybeCreateRunningTodoNotificationRequest maybeTrackerInfo model
                        |> maybeMapToCmd showRunningTodoNotification
                    )
            in
                Return.andThen
                    (Ext.Record.overT2 timeTracker (Todo.TimeTracker.updateNextAlarmAt now)
                        >> foo
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


gotoRunningTodo model =
    Todo.TimeTracker.getMaybeTodoId model.timeTracker
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
                    model |> Model.setFocusInEntityFromTodoId todoId |> Model.switchToContextsView
                )
                (Model.setFocusInEntity # model)
