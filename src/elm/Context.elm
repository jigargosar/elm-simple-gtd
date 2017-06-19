module Context exposing (..)

import Dict
import Document exposing (Document, Id, Revision)
import Firebase exposing (DeviceId)
import GroupDoc
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg as Random
import String.Extra
import Time exposing (Time)
import Tuple2


type alias Name =
    String


type alias Record =
    { name : Name
    , archived : Bool
    }


type alias Model =
    GroupDoc.Model


type alias Store =
    GroupDoc.Store


constructor =
    GroupDoc.constructor


init : Name -> Time -> DeviceId -> Id -> Model
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


findNameById id =
    Store.findById id >>? getName


findByName name =
    Store.findBy (getName >> equals (String.trim name))
