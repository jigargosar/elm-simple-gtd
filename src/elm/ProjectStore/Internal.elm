module ProjectStore.Internal exposing (..)

import Project exposing (Project)
import ProjectStore.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Random.Pcg exposing (Seed)


withModel f (ProjectStore model) =
    f model |> ProjectStore


get f (ProjectStore model) =
    f model


getSeed : Model -> Seed
getSeed =
    get (.seed)


setSeed : Seed -> ModelF
setSeed seed =
    withModel (\model -> { model | seed = seed })


updateSeed : (Model -> Seed) -> ModelF
updateSeed updater model =
    setSeed (updater model) model


getList : Model -> List Project
getList =
    get (.list)


setList : List Project -> ModelF
setList list =
    withModel (\model -> { model | list = list })


updateList : (Model -> List Project) -> ModelF
updateList updater model =
    setList (updater model) model
