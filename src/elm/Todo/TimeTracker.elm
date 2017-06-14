module Todo.TimeTracker exposing (..)

import Document
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


type alias Info =
    { todoId : Todo.Id
    , elapsedTime : Time
    }


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


switchOrStartRunning : Todo.Id -> Time -> Model -> Model
switchOrStartRunning todoId now =
    Maybe.unpack (\_ -> initRunning todoId now) ((\rec -> { rec | todoId = todoId } |> wrap))
        |> Debug.log "switchOrStartRunning"


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


updateNextAlarmAt : Time -> Model -> ( Maybe Info, Model )
updateNextAlarmAt now model =
    case model of
        Nothing ->
            ( Nothing, model )

        Just rec ->
            (if now >= rec.nextAlarmAt then
                let
                    newRec =
                        { rec | nextAlarmAt = now + alarmDelay }

                    info =
                        { todoId = rec.todoId
                        , elapsedTime = getElapsedTime now newRec
                        }
                in
                    ( Just info, newRec )
             else
                ( Nothing, rec )
            )
                |> Tuple.mapSecond wrap


getElapsedTime now rec =
    case rec.state of
        Running startedAt ->
            rec.totalTime + (now - startedAt)

        Paused ->
            rec.totalTime


isTrackingTodo todo =
    Maybe.unwrap False (\rec -> Document.hasId rec.todoId todo)
