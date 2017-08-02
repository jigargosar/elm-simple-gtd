module Project exposing (..)

import GroupDoc
import Json.Encode as E
import Random.Pcg as Random exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import X.Function exposing (..)


nullProject : GroupDoc
nullProject =
    let
        nullId =
            ""
    in
    GroupDoc.constructor nullId "" 0 0 False "" "No Project" False


filterNullProject pred =
    [ nullProject ] |> List.filter pred


isNullProject =
    equals nullProject


sortProjects =
    GroupDoc.sort isNullProject


projectStoreGenerator : DeviceId -> List E.Value -> Random.Generator ProjectStore
projectStoreGenerator =
    GroupDoc.storeGenerator "project-db"
