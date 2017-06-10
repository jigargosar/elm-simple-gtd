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


type State
    = Running Time
    | Paused


type alias ModelRec =
    { todoId : Todo.Id
    , totalTime : Time
    , state : State
    , nextAlarmAt : Time
    }


type alias Model =
    Maybe ModelRec


none : Model
none =
    Nothing


wrap =
    Just


map =
    Maybe.map


toggleStartStop : Todo.Id -> Time -> Model -> Model
toggleStartStop todoId now model =
    case model of
        Nothing ->
            initRunning todoId now

        Just _ ->
            none


alarmDelay =
    10 * Time.minute


initRunning : Todo.Id -> Time -> Model
initRunning todoId now =
    wrap
        { todoId = todoId
        , totalTime = 0
        , state = Running now
        , nextAlarmAt = now + alarmDelay
        }


togglePause : Time -> Model -> Model
togglePause now =
    map
        (\rec ->
            case rec.state of
                Running startedAt ->
                    { rec | totalTime = rec.totalTime + (now - startedAt), state = Paused }

                Paused ->
                    { rec | state = Running now }
        )


getMaybeTodoId =
    map .todoId


updateNextAlarmAt now model =
    case model of
        Nothing ->
            ( Nothing, model )

        Just rec ->
            (if now >= rec.nextAlarmAt then
                let
                    newRec =
                        { rec | nextAlarmAt = now + alarmDelay }
                in
                    ( Just newRec, newRec )
             else
                ( Nothing, rec )
            )
                |> Tuple.mapSecond wrap
