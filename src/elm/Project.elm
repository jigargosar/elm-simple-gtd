module Project exposing (..)

import Firebase.Types exposing (DeviceId)
import GroupDoc
import GroupDoc.Types exposing (..)
import X.Function exposing (..)
import Random.Pcg as Random exposing (..)
import Json.Encode as E


type alias Model =
    GroupDoc.Types.GroupDoc


type alias ModelF =
    Model -> Model


storeGenerator : DeviceId -> List E.Value -> Random.Generator ProjectStore
storeGenerator =
    GroupDoc.storeGenerator "project-db"


getName : Model -> GroupDocName
getName =
    (.name)


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
