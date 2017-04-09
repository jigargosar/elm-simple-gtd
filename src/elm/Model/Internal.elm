module Model.Internal exposing (..)

import Project
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Model.Types exposing (..)
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)
import Todo


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


getTodoStore : Model -> Todo.Store
getTodoStore =
    (.todoStore)


setTodoStore : Todo.Store -> ModelF
setTodoStore todoStore model =
    { model | todoStore = todoStore }


updateTodoStore : (Todo.Store -> Todo.Store) -> ModelF
updateTodoStore updater model =
    { model | todoStore = getTodoStore model |> updater }


getEditMode : Model -> EditMode
getEditMode =
    (.editModel)


setEditMode : EditMode -> ModelF
setEditMode editModel model =
    { model | editModel = editModel }


updateEditModel : (Model -> EditMode) -> ModelF
updateEditModel updater model =
    setEditMode (updater model) model


getMaybeRunningTodoInfo : Model -> Maybe RunningTodo
getMaybeRunningTodoInfo =
    (.maybeRunningTodo)


setMaybeRunningTodo : Maybe RunningTodo -> ModelF
setMaybeRunningTodo maybeRunningTodo model =
    { model | maybeRunningTodo = maybeRunningTodo }


updateMaybeRunningTodo : (Model -> Maybe RunningTodo) -> ModelF
updateMaybeRunningTodo updater model =
    setMaybeRunningTodo (updater model) model


getProjectStore : Model -> Project.Store
getProjectStore =
    (.projectStore)


setProjectStore : Project.Store -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


updateProjectStore : (Model -> Project.Store) -> ModelF
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
