module Model.Internal exposing (..)

import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Model.Types exposing (..)


getSeed : Model -> Seed
getSeed =
    (.seed)


setSeed : Seed -> ModelF
setSeed seed model =
    { model | seed = seed }


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model

getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


setEditMode : EditMode -> ModelF
setEditMode editMode model =
    { model | editMode = editMode }


updateEditMode : (Model -> EditMode) -> ModelF
updateEditMode updater model =
    setEditMode (updater model) model
