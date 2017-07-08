module Todo.TimeTracker exposing (..)

import Document
import Time exposing (Time)
import Todo
import Maybe.Extra as Maybe
import Types
import X.Debug


type State
    = Running Time


type alias Info =
    { todoId : Types.DocId__
    , elapsedTime : Time
    }


type alias ModelRec =
    { todoId : Types.DocId__
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


toggleStartStop : Types.DocId__ -> Time -> Model -> Model
toggleStartStop todoId now model =
    case model of
        Nothing ->
            initRunning todoId now

        Just _ ->
            none


alarmDelay =
    10 * Time.minute


initRunning : Types.DocId__ -> Time -> Model
initRunning todoId now =
    wrap
        { todoId = todoId
        , state = Running now
        , nextAlarmAt = now + alarmDelay
        }


switchOrStartRunning : Types.DocId__ -> Time -> Model -> Model
switchOrStartRunning todoId now =
    let
        _ =
            X.Debug.log "switchOrStartRunning" "foo"
    in
        Maybe.unpack (\_ -> initRunning todoId now) ((\rec -> { rec | todoId = todoId } |> wrap))


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
            now - startedAt


isTrackingTodo todo =
    Maybe.unwrap False (\rec -> Document.hasId rec.todoId todo)
