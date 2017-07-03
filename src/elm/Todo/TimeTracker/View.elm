module Todo.TimeTracker.View exposing (..)

import X.Time
import Material
import Model
import Todo.TimeTracker exposing (State(..))
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Todo
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


-- View


type alias ViewModel =
    { displayText : String
    , displayTime : String
    }


createViewModel appModel tracker =
    let
        ( elapsedTime, playPauseIconName ) =
            case tracker.state of
                Running startedAt ->
                    ( tracker.totalTime + (appModel.now - startedAt), "pause" )

                Paused ->
                    ( tracker.totalTime, "play_arrow" )

        todoText =
            Model.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
        { displayText = todoText
        , displayTime = X.Time.toHHMMSS elapsedTime
        , playPauseIconName = playPauseIconName
        , onStop = Model.onTodoStopRunning
        , onTogglePause = Model.onTodoTogglePaused
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
            , Material.iconBtn vm.playPauseIconName vm.onTogglePause
            , Material.iconBtn "stop" vm.onStop
            ]
        ]
