module Project exposing (..)

import GroupDoc
import Json.Encode as E
import Random.Pcg as Random exposing (..)
import Types.Firebase exposing (..)
import Types.GroupDoc exposing (..)
import X.Function exposing (..)


type alias Model =
    Types.GroupDoc.GroupDoc


type alias ModelF =
    Model -> Model


storeGenerator : DeviceId -> List E.Value -> Random.Generator ProjectStore
storeGenerator =
    GroupDoc.storeGenerator "project-db"


getName : Model -> GroupDocName
getName =
    .name


constructor =
    GroupDoc.constructor


null : Model
null =
    constructor nullId "" 0 0 False "" "No Project" False


nullId =
    ""


isNullId =
    equals nullId


filterNull pred =
    [ null ] |> List.filter pred


isNull =
    equals null


sort =
    GroupDoc.sort isNull
