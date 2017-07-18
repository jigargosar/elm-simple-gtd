module Todo.TimeTracker.View exposing (..)

import Model.Todo
import Msg
import X.Time
import Mat
import Todo.TimeTracker exposing (State(..))
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Todo
import Html exposing (..)
import Html.Attributes exposing (..)
import TodoMsg


-- View


createViewModel appModel tracker =
    let
        elapsedTime =
            Todo.TimeTracker.getElapsedTime appModel.now tracker

        todoText =
            Model.Todo.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
        { displayText = todoText
        , displayTime = X.Time.toHHMMSS elapsedTime
        , onStop = TodoMsg.onStopRunningTodo
        }


maybe appModel =
    appModel.timeTracker ?|> createViewModel appModel >> view


view vm =
    div [ class "layout vertical", style [ "position" => "relative", "top" => "5px" ] ]
        [ div [ class "ellipsis" ] [ text vm.displayText ]
        , div [ class "layout horizontal start", style [ "position" => "relative", "top" => "-5px" ] ]
            [ div
                [ class "self-center"
                , style [ "margin-right" => "1rem" ]
                ]
                [ text vm.displayTime ]
            , Mat.iconBtn2 Msg.OnMdl "stop" vm.onStop
            ]
        ]
