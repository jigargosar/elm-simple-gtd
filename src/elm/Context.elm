module Context exposing (..)

import Document exposing (Document, Revision)
import Document.Types exposing (DeviceId, DocId)
import GroupDoc
import GroupDoc.Types exposing (..)
import X.Function exposing (..)
import Json.Encode as E
import Random.Pcg as Random
import Time exposing (Time)


type alias Model =
    GroupDoc.Types.GroupDoc


type alias Store =
    GroupDoc.Store


constructor =
    GroupDoc.constructor


init : GroupDocName -> Time -> DeviceId -> DocId -> Model
init name now deviceId id =
    constructor id "" now now False deviceId name False


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


setName name model =
    { model | name = name }


storeGenerator : DeviceId -> List E.Value -> Random.Generator Store
storeGenerator =
    GroupDoc.storeGenerator "context-db"
