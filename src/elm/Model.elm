module Model exposing (..)

import Context
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
import Set
import Time exposing (Time)
import Todo.Types exposing (..)
import Todo
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model.Types exposing (..)
import Types exposing (..)


init : Time -> List EncodedTodo -> List EncodedProject -> List Context.Encoded -> Model
init now encodedTodoList encodedProjectList encodedContextList =
    let
        storeGenerator =
            Random.map3 (,,)
                (todoStoreGenerator encodedTodoList)
                (ProjectStore.generator encodedProjectList)
                (Context.storeGenerator encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.step storeGenerator (Random.seedFromTime now)
    in
        { now = now
        , todoStore = todoStore
        , projectStore = projectStore
        , contextStore = contextStore
        , editModel = NotEditing
        , mainViewType = GroupByContextView
        , seed = seed
        , maybeRunningTodo = Nothing
        , keyboardState = Keyboard.init
        , selection = Set.empty
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


toggleSelection todo m =
    let
        todoId =
            Todo.getId todo

        selection =
            m.selection
    in
        if (Set.member todoId selection) then
            { m | selection = Set.remove todoId selection }
        else
            { m | selection = Set.insert todoId selection }


clearSelection m =
    { m | selection = Set.empty }


getMaybeSelectedTodo m =
    let
        selection =
            m.selection
    in
        if Set.size selection == 1 then
            Set.toList selection |> List.head ?+> (PouchDB.findById # m.todoStore)
        else
            Nothing


getSelectedTodoIdSet =
    (.selection)


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


keyboardState =
    { get = .keyboardState, set = (\s b -> { b | keyboardState = s }) }


todoStore =
    { get = .todoStore, set = (\s b -> { b | todoStore = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }


update lens smallF big =
    lens.set (smallF (lens.get big)) big


update2 lens l2 smallF big =
    lens.set (smallF (l2.get big) (lens.get big)) big
