module Model exposing (..)

import Ext.Keyboard as Keyboard
import Model.Internal exposing (..)
import Msg exposing (Return)
import PouchDB
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
import Todo.Types exposing (..)
import Todo
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model.Types exposing (..)
import Types exposing (..)


init : Time -> List EncodedTodo -> List EncodedProject -> Model
init now encodedTodoList encodedProjectStore =
    let
        storeGenerator =
            Random.map2 (,)
                (todoStoreGenerator encodedTodoList)
                (ProjectStore.generator encodedProjectStore)

        ( ( todoStore, projectStore ), seed ) =
            Random.step storeGenerator (Random.seedFromTime now)
    in
        { now = now
        , todoStore = todoStore
        , editModel = NotEditing
        , mainViewType = AllByTodoContextView
        , seed = seed
        , maybeRunningTodo = Nothing
        , projectStore = projectStore
        , keyboardState = Keyboard.init
        }


todoStoreGenerator : List EncodedTodo -> Random.Generator TodoStore
todoStoreGenerator =
    PouchDB.generator "todo-db" Todo.encode Todo.decoder


findProjectByName projectName =
    getProjectStore >> ProjectStore.findByName projectName


getMaybeProjectNameOfTodo : Todo -> Model -> Maybe ProjectName
getMaybeProjectNameOfTodo todo model =
    Todo.getMaybeProjectId todo ?+> ProjectStore.findNameById # (getProjectStore model)


insertProjectIfNotExist2 : ProjectName -> ModelF
insertProjectIfNotExist2 projectName =
    (update2 projectStore now)
        (ProjectStore.insertIfNotExistByName projectName)


insertProjectIfNotExist : ProjectName -> ModelF
insertProjectIfNotExist projectName =
    apply2With ( getNow, getProjectStore )
        (ProjectStore.insertIfNotExistByName projectName >>> setProjectStore)


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


todoStore =
    { get = .todoStore, set = (\s b -> { b | todoStore = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }


update lens smallF big =
    lens.set (smallF (lens.get big)) big


update2 lens l2 smallF big =
    lens.set (smallF (l2.get big) (lens.get big)) big
