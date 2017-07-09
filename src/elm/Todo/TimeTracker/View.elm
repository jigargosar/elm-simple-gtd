module Todo.TimeTracker.View exposing (..)

import Msg
import X.Time
import Mat
import Model
import Todo.TimeTracker exposing (State(..))
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Todo
import Html exposing (..)
import Html.Attributes exposing (..)


-- View


createViewModel appModel tracker =
    let
        elapsedTime =
            Todo.TimeTracker.getElapsedTime appModel.now tracker

        todoText =
            Model.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
        { displayText = todoText
        , displayTime = X.Time.toHHMMSS elapsedTime
        , onStop = Model.onTodoStopRunning
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
