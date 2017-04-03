module Model exposing (..)

import EditModel
import Model.Internal exposing (..)
import Project
import RunningTodo exposing (RunningTodo)
import Dict
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import TodoList
import Todo.Types exposing (..)
import Todo
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model.Types exposing (..)
import Types exposing (..)


getMainViewType : Model -> MainViewType
getMainViewType =
    (.mainViewType)


setMainViewType : MainViewType -> ModelF
setMainViewType =
    MainViewTypeField >> set


updateMainViewType : (Model -> MainViewType) -> ModelF
updateMainViewType updater model =
    setMainViewType (updater model) model


getNow : Model -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


updateNow : (Model -> Time) -> ModelF
updateNow updater model =
    { model | now = updater model }


set : ModelField -> ModelF
set field model =
    case field of
        NowField now ->
            { model | now = now }

        MainViewTypeField mainViewType ->
            { model | mainViewType = mainViewType }


update : (Model -> ModelField) -> ModelF
update updater model =
    set (updater model) model


generate : Random.Generator a -> Model -> ( a, Model )
generate generator m =
    Random.step generator (m.seed)
        |> Tuple.mapSecond (setSeed # m)


init now encodedTodoList encodedProjectList =
    { now = now
    , todoList = TodoList.decodeTodoList encodedTodoList
    , editModel = EditModel.init
    , mainViewType = AllByTodoContextView
    , seed = Random.seedFromTime now
    , runningTodo = RunningTodo.init
    , projectList = Project.decodeProjectList encodedProjectList
    }
