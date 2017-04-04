module Model exposing (..)

import Model.Internal exposing (..)
import Msg exposing (Return)
import Project exposing (Project, EncodedProject, ProjectId, ProjectName)
import ProjectStore
import ProjectStore.Types exposing (ProjectStore)
import RunningTodo exposing (RunningTodo)
import Dict
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import Ext.Random as Random
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
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
        , editModel = NotEditing
        , mainViewType = AllByTodoContextView
        , seed = initialSeed
        , maybeRunningTodo = Nothing
        , projectStore = projectStore
        }


updateProjectStoreFromTuple : (ProjectStore -> ( Project, ProjectStore )) -> Model -> ( Project, Model )
updateProjectStoreFromTuple f m =
    let
        ( project, projectStore ) =
            f (getProjectStore m)
    in
        ( project, setProjectStore projectStore m )


addNewProject : ProjectName -> Model -> ( Project, Model )
addNewProject projectName model =
    updateProjectStoreFromTuple (ProjectStore.addNewProject projectName (getNow model)) model


findProjectByName projectName =
    getProjectStore >> ProjectStore.findProjectByName projectName


getMaybeProjectNameOfTodo : Todo -> Model -> Maybe ProjectName
getMaybeProjectNameOfTodo =
    Todo.getMaybeProjectId >> findProjectNameByMaybeId


findProjectNameByMaybeId maybeProjectId model =
    maybeProjectId ?+> ProjectStore.findProjectNameById # (getProjectStore model)
