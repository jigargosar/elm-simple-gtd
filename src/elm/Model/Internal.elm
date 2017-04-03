module Model.Internal exposing (..)

import EditModel.Types exposing (..)
import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Model.Types exposing (..)
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import TodoList.Types exposing (TodoList)


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


getTodoList : Model -> TodoList
getTodoList =
    (.todoList)


setTodoList : TodoList -> ModelF
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (TodoList -> TodoList) -> ModelF
updateTodoList updater model =
    { model | todoList = getTodoList model |> updater }



--updateTodoListTuple2 : (TodoList -> ( x, TodoList )) -> Model -> ( x, Model )
--updateTodoListTuple2 updater model =
--    let
--        ( x, todoList ) =
--            getTodoList model |> updater
--    in
--        ( x, { model | todoList = todoList } )


getEditModel : Model -> EditModel
getEditModel =
    (.editModel)


setEditModel : EditModel -> ModelF
setEditModel editModel model =
    { model | editModel = editModel }


updateEditModel : (Model -> EditModel) -> ModelF
updateEditModel updater model =
    setEditModel (updater model) model


getMaybeRunningTodo : Model -> Maybe RunningTodo
getMaybeRunningTodo =
    (.maybeRunningTodo)


setMaybeRunningTodo : Maybe RunningTodo -> ModelF
setMaybeRunningTodo maybeRunningTodo model =
    { model | maybeRunningTodo = maybeRunningTodo }


updateMaybeRunningTodo : (Model -> Maybe RunningTodo) -> ModelF
updateMaybeRunningTodo updater model =
    setMaybeRunningTodo (updater model) model


getProjectStore : Model -> ProjectStore
getProjectStore =
    (.projectStore)


setProjectStore : ProjectStore -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


updateProjectStore : (Model -> ProjectStore) -> ModelF
updateProjectStore updater model =
    setProjectStore (updater model) model


getMainViewType : Model -> MainViewType
getMainViewType =
    (.mainViewType)


setMainViewType : MainViewType -> ModelF
setMainViewType mainViewType model =
    { model | mainViewType = mainViewType }


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
