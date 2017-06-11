port module Update.Todo exposing (..)

import Document
import Ext.Record
import Model exposing (NotificationRequest)
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


port showRunningTodoNotification : NotificationRequest -> Cmd msg


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


onTodoMsgWithTime andThenUpdate todoMsg now =
    case todoMsg of
        ToggleRunning todoId ->
            over Model.timeTracker (Todo.TimeTracker.toggleStartStop todoId now)

        InitRunning todoId ->
            set Model.timeTracker (Todo.TimeTracker.initRunning todoId now)

        TogglePaused ->
            over Model.timeTracker (Todo.TimeTracker.togglePause now)

        StopRunning ->
            set Model.timeTracker Todo.TimeTracker.none

        GotoRunning ->
            map (Model.gotoRunningTodo)
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
                    (Ext.Record.overT2 Model.timeTracker (Todo.TimeTracker.updateNextAlarmAt now)
                        >> foo
                    )

        RunningTodoNotificationResponse res ->
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
