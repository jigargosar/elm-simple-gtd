module Todo.TimeTracker exposing (..)

import Document
import Maybe.Extra as Maybe
import Time exposing (Time)
import Types.Document exposing (..)


type State
    = Running Time


type alias Info =
    { todoId : DocId
    , elapsedTime : Time
    }


type alias ModelRec =
    { todoId : DocId
    , state : State
    , nextAlarmAt : Time
    , now : Time
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


toggleStartStop : DocId -> Time -> Model -> Model
toggleStartStop todoId now model =
    case model of
        Nothing ->
            initRunning todoId now

        Just _ ->
            none


alarmDelay =
    10 * Time.minute


initRunning : DocId -> Time -> Model
initRunning todoId now =
    wrap
        { todoId = todoId
        , state = Running now
        , nextAlarmAt = now + alarmDelay
        , now = now
        }


switchOrStartRunning : DocId -> Time -> Model -> Model
switchOrStartRunning todoId now =
    Maybe.unpack (\_ -> initRunning todoId now) (\rec -> { rec | todoId = todoId } |> wrap)


getMaybeTodoId =
    map .todoId


updateNextAlarmAt : Time -> Model -> ( Maybe Info, Model )
updateNextAlarmAt now model =
    model
        |> Maybe.map (setNow now)
        |> (\model ->
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
                                    , elapsedTime = getElapsedTime newRec
                                    }
                            in
                            ( Just info, newRec )
                         else
                            ( Nothing, rec )
                        )
                            |> Tuple.mapSecond wrap
           )


setNow now rec =
    { rec | now = now }


getElapsedTime rec =
    case rec.state of
        Running startedAt ->
            rec.now - startedAt


isTrackingTodo todo =
    Maybe.unwrap False (\rec -> Document.hasId rec.todoId todo)
