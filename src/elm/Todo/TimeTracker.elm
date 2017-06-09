module Todo.TimeTracker exposing (..)

import Material
import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Polymer.Paper as Paper


type alias ModelRec =
    { todoId : Todo.Id
    , startedAt : Time
    }


type alias Model =
    Maybe ModelRec


init : Model
init =
    Nothing


wrap =
    Just


start : Todo.Id -> Time -> Model
start todoId now =
    { todoId = todoId
    , startedAt = now
    }
        |> wrap



-- View


type alias ViewModel =
    { displayText : String
    , displayTime : String
    }


createViewModel appModel tracker =
    { displayText = tracker.todoId
    , displayTime = toString tracker.startedAt
    }


maybeView appModel =
    appModel.timeTracker ?|> createViewModel appModel >> view


view vm =
    Paper.item [ class "w--100" ]
        [ Paper.itemBody []
            [ div [] [ text vm.displayText ]
            , div [ class "row" ]
                [ div [ class "col" ]
                    [ text vm.displayTime ]
                , div [ class "col" ]
                    [ Material.icon "play_arrow"
                    , Material.icon "stop"
                    , Material.icon "pause"
                    ]
                ]
            ]
        ]
