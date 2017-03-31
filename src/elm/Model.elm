module Model exposing (..)

import RunningTodoDetails exposing (RunningTodoDetails)
import Dict
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo as Todo exposing (TodoGroup, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Types exposing (MainViewType, Model, ModelF)


getMainViewType : Model -> MainViewType
getMainViewType =
    (.mainViewType)


setMainViewType : MainViewType -> ModelF
setMainViewType mainViewType model =
    { model | mainViewType = mainViewType }


getNow : Model -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


setSeed__ : Seed -> ModelF
setSeed__ seed model =
    { model | seed = seed }


generate : Random.Generator a -> Model -> ( a, Model )
generate generator m =
    Random.step generator (m.seed)
        |> Tuple.mapSecond (setSeed__ # m)
