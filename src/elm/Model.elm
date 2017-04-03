module Model exposing (..)

import EditModel
import Model.Internal exposing (..)
import Msg exposing (Return)
import Project exposing (EncodedProject, ProjectName)
import ProjectStore
import ProjectStore.Types exposing (ProjectStore)
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


generate : (Model -> Random.Generator a) -> Model -> ( a, Model )
generate generatorFn m =
    Random.step (generatorFn m) (m.seed)
        |> Tuple.mapSecond (setSeed # m)


init : Time -> EncodedTodoList -> List EncodedProject -> Model
init now encodedTodoList encodedProjectStore =
    let
        initialSeed =
            Random.seedFromTime now

        ( projectStore, newSeed ) =
            Random.step (ProjectStore.generator encodedProjectStore) initialSeed
    in
        { now = now
        , todoList = TodoList.decodeTodoList encodedTodoList
        , editModel = EditModel.init
        , mainViewType = AllByTodoContextView
        , seed = initialSeed
        , maybeRunningTodo = Nothing
        , projectStore = projectStore
        }


updateProjectStoreFromTuple : (ProjectStore -> ( x, ProjectStore )) -> Model -> ( x, Model )
updateProjectStoreFromTuple f m =
    let
        ( x, projectStore ) =
            f (getProjectStore m)
    in
        ( x, setProjectStore projectStore m )


addNewProject projectName model =
    model
        |> updateProjectStoreFromTuple
            (ProjectStore.addNewProject projectName (getNow model))


findProjectByName projectName =
    getProjectStore >> ProjectStore.findProjectByName projectName


getProjectNameOfTodo : Todo -> Model -> ProjectName
getProjectNameOfTodo todo model =
    Todo.getMaybeProjectId todo
        ?+> (\id ->
                model |> getProjectStore >> ProjectStore.findProjectNameById id
            )
        ?= ""
