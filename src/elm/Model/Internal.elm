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

getEditState : Model -> EditState
getEditState =
    (.editState)


setEditState : EditState -> ModelF
setEditState editState model =
    { model | editState = editState }


updateEditState : (Model -> EditState) -> ModelF
updateEditState updater model =
    setEditState (updater model) model
