module Context exposing (..)

import Document exposing (Document, Revision)
import Firebase exposing (DeviceId)
import GroupDoc
import X.Function exposing (..)
import Json.Encode as E
import Random.Pcg as Random
import Time exposing (Time)
import Types


type alias Name =
    GroupDoc.Name


type alias Model =
    GroupDoc.Model


type alias Store =
    GroupDoc.Store


constructor =
    GroupDoc.constructor


init : Name -> Time -> DeviceId -> Types.DocId -> Model
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
