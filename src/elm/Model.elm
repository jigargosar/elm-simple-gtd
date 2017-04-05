module Model exposing (..)

import Model.Internal exposing (..)
import Model.TodoList
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
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model.Types exposing (..)
import Types exposing (..)


generate : (Model -> Random.Generator a) -> Model -> ( a, Model )
generate generatorFn m =
    Random.step (generatorFn m) (m.seed)
        |> Tuple.mapSecond (setSeed # m)


init : Time -> List EncodedTodo -> List EncodedProject -> Model
init now encodedTodoList encodedProjectStore =
    let
        initialSeed =
            Random.seedFromTime now

        ( projectStore, newSeed ) =
            Random.step (ProjectStore.generator encodedProjectStore) initialSeed

        ( todoStore, newSeed2 ) =
            Random.step (Model.TodoList.generator encodedTodoList) newSeed
    in
        { now = now
        , todoList = todoStore
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


findProjectByName projectName =
    getProjectStore >> ProjectStore.findByName projectName


getMaybeProjectNameOfTodo : Todo -> Model -> Maybe ProjectName
getMaybeProjectNameOfTodo =
    Todo.getMaybeProjectId >> findProjectNameByMaybeId


findProjectNameByMaybeId maybeProjectId model =
    maybeProjectId ?+> ProjectStore.findNameById # (getProjectStore model)


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }


update lens smallF big =
    lens.set (smallF (lens.get big)) big


update2 lens l2 smallF big =
    lens.set (smallF (l2.get big) (lens.get big)) big
