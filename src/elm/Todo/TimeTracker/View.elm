module Todo.TimeTracker.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Mat
import Models.Todo
import Todo
import Todo.TimeTracker exposing (State(..))
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Time


-- View


createViewModel config appModel tracker =
    let
        elapsedTime =
            Todo.TimeTracker.getElapsedTime tracker

        todoText =
            Models.Todo.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
    { displayText = todoText
    , displayTime = X.Time.toHHMMSS elapsedTime
    , onStop = config.onStopRunningTodoMsg
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
