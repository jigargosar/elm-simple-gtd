module Model exposing (..)

import Context
import Dict.Extra
import Ext.Keyboard as Keyboard
import Model.Internal exposing (..)
import Model.TodoStore
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
import Todo
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model.Types exposing (..)
import Types exposing (..)


init : Time -> List Todo.Encoded -> List EncodedProject -> List Context.Encoded -> Model
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


todoStoreGenerator : List Todo.Encoded -> Random.Generator TodoStore
todoStoreGenerator =
    PouchDB.generator "todo-db" Todo.encode Todo.decoder


findProjectByName name =
    getProjectStore >> ProjectStore.findByName name


findContextByName name =
    .contextStore >> Context.findByName name


getContextByIdDict =
    (.contextStore) >> Context.byIdDict


getActiveContexts =
    (.contextStore) >> PouchDB.asList


getActiveProjects =
    (.projectStore) >> PouchDB.asList


getEncodedContextNames =
    .contextStore >> Context.getEncodedNames


getMaybeProjectNameOfTodo : Todo.Model -> Model -> Maybe ProjectName
getMaybeProjectNameOfTodo todo model =
    Todo.getProjectId todo |> ProjectStore.findNameById # (getProjectStore model)


getContextNameOfTodo : Todo.Model -> Model -> Maybe Context.Name
getContextNameOfTodo todo model =
    Todo.getContextId todo |> Context.findNameById # (model.contextStore)


insertProjectIfNotExist2 : ProjectName -> ModelF
insertProjectIfNotExist2 projectName =
    (update2 projectStore now)
        (ProjectStore.insertIfNotExistByName projectName)


insertProjectIfNotExist : ProjectName -> ModelF
insertProjectIfNotExist projectName =
    apply2With ( getNow, getProjectStore )
        (ProjectStore.insertIfNotExistByName projectName >>> setProjectStore)


insertContextIfNotExist : Context.Name -> ModelF
insertContextIfNotExist name =
    apply2With ( getNow, .contextStore )
        (Context.insertIfNotExistByName name
            >>> (\contextStore model -> { model | contextStore = contextStore })
        )


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


getActiveTodoList =
    .todoStore >> PouchDB.reject (anyPass [ Todo.isDeleted, Todo.isDone ])


getActiveTodoListGroupedByContextId =
    getActiveTodoList >> Dict.Extra.groupBy (Todo.getContextId)


getActiveTodoListGroupedByProjectId =
    getActiveTodoList >> Dict.Extra.groupBy (Todo.getProjectId)


updateTodoFromEditTodoModel : EditTodoModel -> ModelF
updateTodoFromEditTodoModel { contextName, projectName, todoText, todoId } =
    apply3Uncurry ( findContextByName contextName, findProjectByName projectName, identity )
        (\maybeContext maybeProject ->
            Model.TodoStore.updateTodoById
                [ Todo.SetText todoText
                , Todo.SetProjectId (maybeProject ?|> Project.getId ?= "")
                , Todo.SetContextId (maybeContext ?|> Context.getId ?= "")
                ]
                todoId
        )


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


keyboardState =
    { get = .keyboardState, set = (\s b -> { b | keyboardState = s }) }


todoStore =
    { get = .todoStore, set = (\s b -> { b | todoStore = s }) }


contextStore =
    { get = .contextStore, set = (\s b -> { b | contextStore = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }


update lens smallF big =
    lens.set (smallF (lens.get big)) big


update2 lens l2 smallF big =
    lens.set (smallF (l2.get big) (lens.get big)) big
