module Context exposing (..)

import GroupDoc
import Json.Encode as E
import Random.Pcg as Random
import Types.Document exposing (..)
import Types.GroupDoc exposing (..)
import X.Function exposing (..)


type alias Model =
    Types.GroupDoc.GroupDoc


constructor =
    GroupDoc.constructor


null : Model
null =
    constructor nullId "" 0 0 False "" "Inbox" False


nullId =
    ""


isNullId =
    equals nullId


filterNull pred =
    [ null ] |> List.filter pred


sort =
    GroupDoc.sort isNull


isNull =
    equals null


getName =
    .name


storeGenerator : DeviceId -> List E.Value -> Random.Generator ContextStore
storeGenerator =
    GroupDoc.storeGenerator "context-db"
