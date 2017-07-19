module Todo.TimeTracker.View exposing (..)

import Model.Todo
import X.Time
import Mat
import Todo.TimeTracker exposing (State(..))
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Todo
import Html exposing (..)
import Html.Attributes exposing (..)


-- View


createViewModel config appModel tracker =
    let
        elapsedTime =
            Todo.TimeTracker.getElapsedTime appModel.now tracker

        todoText =
            Model.Todo.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
        { displayText = todoText
        , displayTime = X.Time.toHHMMSS elapsedTime
        , onStop = config.onStopRunningTodo
        , onMdl = config.onMdl
        }


maybe config appModel =
    appModel.timeTracker ?|> createViewModel config appModel >> view


view vm =
    div [ class "layout vertical", style [ "position" => "relative", "top" => "5px" ] ]
        [ div [ class "ellipsis" ] [ text vm.displayText ]
        , div [ class "layout horizontal start", style [ "position" => "relative", "top" => "-5px" ] ]
            [ div
                [ class "self-center"
                , style [ "margin-right" => "1rem" ]
                ]
                [ text vm.displayTime ]
            , Mat.iconBtn2 vm.onMdl "stop" vm.onStop
            ]
        ]
