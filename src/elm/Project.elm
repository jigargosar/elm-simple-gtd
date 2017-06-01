module Project exposing (..)

import Dict
import Document exposing (Document, Id, Revision)
import Firebase exposing (DeviceId)
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


type alias Record =
    { name : Name
    }


type alias Project =
    Document Record


type alias Model =
    Project


type alias ModelF =
    Model -> Model


type alias Name =
    String


type alias Store =
    Store.Store Record


getEncodedProjectNames =
    Store.map (getName >> E.string) >> E.list


getProjectIdToNameDict =
    Store.map (apply2 ( Document.getId, getName )) >> Dict.fromList


findNameById id =
    Store.findById id >>? getName


storeGenerator : DeviceId -> List Encoded -> Random.Generator Store
storeGenerator =
    Store.generator "project-db" otherFieldsEncoder decoder


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


constructor id rev createdAt modifiedAt deleted deviceId name =
    { id = id
    , rev = rev
    , deviceId = deviceId
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = deleted
    , dirty = False
    , name = name
    }


init : Name -> Time -> DeviceId -> Id -> Model
init name now deviceId id =
    constructor id "" now now False deviceId name


null : Model
null =
    constructor "" "" 0 0 False "" "<No Project>"


filterNull pred =
    [ null ] |> List.filter pred


isNull =
    equals null


type alias Encoded =
    E.Value


otherFieldsEncoder : Document Record -> List ( String, E.Value )
otherFieldsEncoder project =
    [ "name" => E.string (getName project) ]


decoder : Decoder Project
decoder =
    D.decode constructor
        |> Document.documentFieldsDecoder
        |> D.required "name" D.string
