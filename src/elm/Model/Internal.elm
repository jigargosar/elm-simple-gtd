module Model.Internal exposing (..)

import EditModel.Types exposing (..)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)
import RunningTodo exposing (RunningTodo)


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


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
