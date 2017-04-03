module Model exposing (..)

import EditModel
import Model.Internal exposing (..)
import Msg exposing (Return)
import Project exposing (EncodedProjectList)
import ProjectList
import RunningTodo exposing (RunningTodo)
import Dict
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import Ext.Random as Random
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import TodoList
import Todo.Types exposing (..)
import Todo
import TodoList.Types exposing (EncodedTodoList)
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


generate : (Model -> Random.Generator a) -> Model -> ( a, Model )
generate generatorFn m =
    Random.step (generatorFn m) (m.seed)
        |> Tuple.mapSecond (setSeed # m)


init : Time -> EncodedTodoList -> EncodedProjectList -> Model
init now encodedTodoList encodedProjectList =
    let
        initialSeed =
            Random.seedFromTime now

        ( projectList, newSeed ) =
            Random.step (ProjectList.generator encodedProjectList) initialSeed
    in
        { now = now
        , todoList = TodoList.decodeTodoList encodedTodoList
        , editModel = EditModel.init
        , mainViewType = AllByTodoContextView
        , seed = initialSeed
        , maybeRunningTodo = Nothing
        , projectList = projectList
        }
