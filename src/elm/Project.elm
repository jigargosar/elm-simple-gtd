module Project exposing (..)


import Document exposing (Document, Id, Revision)
import Firebase exposing (DeviceId)
import GroupDoc




import X.Function exposing (..)

import Random.Pcg as Random exposing (..)



import Json.Encode as E

import Time exposing (Time)


type alias Name =
    GroupDoc.Name


type alias Model =
    GroupDoc.Model


type alias Store =
    GroupDoc.Store


type alias ModelF =
    Model -> Model


storeGenerator : DeviceId -> List E.Value -> Random.Generator Store
storeGenerator =
    GroupDoc.storeGenerator "project-db"


getName : Model -> GroupDoc.Name
getName =
    (.name)


setName : GroupDoc.Name -> ModelF
setName name model =
    { model | name = name }


constructor =
    GroupDoc.constructor


init : GroupDoc.Name -> Time -> DeviceId -> Id -> Model
init name now deviceId id =
    constructor id "" now now False deviceId name False


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
