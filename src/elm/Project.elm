module Project exposing (..)

import Dict
import Document exposing (Document, Id, Revision)
import Firebase exposing (DeviceId)
import GroupDoc
import Maybe.Extra
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Random.Pcg as Random exposing (..)
import Ext.Random as Random
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import String.Extra
import Time exposing (Time)


type alias Project =
    GroupDoc.Model


type alias Model =
    Project


type alias ModelF =
    Model -> Model


type alias Name =
    String


type alias Store =
    GroupDoc.Store


findNameById id =
    Store.findById id >>? getName


storeGenerator : DeviceId -> List E.Value -> Random.Generator Store
storeGenerator =
    GroupDoc.storeGenerator "project-db"


findByName projectName =
    Store.findBy (nameEquals (String.trim projectName))


nameEquals name =
    getName >> equals name


setId : Id -> ModelF
setId id model =
    { model | id = id }


updateId : (Model -> Id) -> ModelF
updateId updater model =
    setId (updater model) model


getRev : Model -> Revision
getRev =
    (.rev)


setRev : Revision -> ModelF
setRev rev model =
    { model | rev = rev }


updateRev : (Model -> Revision) -> ModelF
updateRev updater model =
    setRev (updater model) model


getName : Model -> Name
getName =
    (.name)


setName : Name -> ModelF
setName name model =
    { model | name = name }


updateName : (Model -> Name) -> ModelF
updateName updater model =
    setName (updater model) model


constructor =
    GroupDoc.constructor


init : Name -> Time -> DeviceId -> Id -> Model
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
