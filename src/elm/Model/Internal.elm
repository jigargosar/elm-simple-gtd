module Model.Internal exposing (..)

import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Model.Types exposing (..)
import RunningTodo exposing (RunningTodo)
import Time exposing (Time)


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


getTodoStore : Model -> TodoStore
getTodoStore =
    (.todoStore)


setTodoStore : TodoStore -> ModelF
setTodoStore todoStore model =
    { model | todoStore = todoStore }


updateTodoStore : (TodoStore -> TodoStore) -> ModelF
updateTodoStore updater model =
    { model | todoStore = getTodoStore model |> updater }


getEditModel : Model -> EditModel
getEditModel =
    (.editModel)


setEditModel : EditModel -> ModelF
setEditModel editModel model =
    { model | editModel = editModel }


updateEditModel : (Model -> EditModel) -> ModelF
updateEditModel updater model =
    setEditModel (updater model) model


getMaybeRunningTodoInfo : Model -> Maybe RunningTodo
getMaybeRunningTodoInfo =
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
