module Update.Todo exposing (..)

import Ext.Record
import Model
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker


over =
    Ext.Record.over >>> Return.map


set =
    Ext.Record.set >>> Return.map


map =
    Return.map


command =
    Return.command


onTodoMsgWithTime andThenUpdate todoMsg now =
    case todoMsg of
        Model.OnTodoToggleRunning todoId ->
            over Model.timeTracker (Todo.TimeTracker.toggleStartStop todoId now)

        Model.OnTodoInitRunning todoId ->
            set Model.timeTracker (Todo.TimeTracker.initRunning todoId now)

        Model.OnTodoTogglePaused ->
            over Model.timeTracker (Todo.TimeTracker.togglePause now)

        Model.OnTodoStopRunning ->
            set Model.timeTracker Todo.TimeTracker.none

        Model.OnGotoRunningTodo ->
            map (Model.gotoRunningTodo)
                >> andThenUpdate Model.OnSetDomFocusToFocusInEntity

        Model.OnRunningTodoNotificationClicked res ->
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
