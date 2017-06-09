module Todo.TimeTracker.View exposing (..)

import Ext.Time
import Material
import Model
import Todo.TimeTracker exposing (State(..))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


-- View


type alias ViewModel =
    { displayText : String
    , displayTime : String
    }


createViewModel appModel tracker =
    let
        ( elapsedTime, controlIcon ) =
            case tracker.state of
                Running startedAt ->
                    ( tracker.totalTime + (appModel.now - startedAt), "pause" )

                Paused ->
                    ( tracker.totalTime, "play_arrow" )

        todoText =
            Model.findTodoById tracker.todoId appModel ?|> Todo.getText ?= tracker.todoId
    in
        { displayText = todoText
        , displayTime = Ext.Time.toHHMMSS elapsedTime
        , controlIcon = controlIcon
        }


maybe appModel =
    appModel.timeTracker ?|> createViewModel appModel >> view


view vm =
    div [ class "w100 layout vertical" ]
        [ div [ class "flex-auto ellipsis" ] [ text vm.displayText ]
        , div [ class "flex-auto layout horizontal" ]
            [ div [ class "flex-auto" ] [ text vm.displayTime ]
            , div [ class "" ]
                [ Material.iconButton vm.controlIcon
                , Material.iconButton "cancel"
                , Material.iconButton "done"
                ]
            ]
        ]
