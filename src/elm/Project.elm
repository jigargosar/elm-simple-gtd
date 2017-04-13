module Project exposing (..)

import Dict
import Document
import Maybe.Extra
import PouchDB
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
    { name : Name }


type alias Project =
    PouchDB.Document Record


type alias Model =
    Project


type alias ModelF =
    Model -> Model


type alias Name =
    String


type alias Id =
    PouchDB.Id


type alias Store =
    PouchDB.Store Record


getEncodedProjectNames =
    PouchDB.map (getName >> E.string) >> E.list


getProjectIdToNameDict =
    PouchDB.map (apply2 ( Document.getId, getName )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? getName


storeGenerator : List Encoded -> Random.Generator Store
storeGenerator =
    PouchDB.generator "project-db" encode decoder


findByName projectName =
    PouchDB.findBy (nameEquals (String.trim projectName))


insertIfNotExistByName projectName now store =
    if (String.Extra.isBlank projectName) then
        store
    else
        findByName projectName store
            |> Maybe.Extra.unpack
                (\_ ->
                    PouchDB.insert (init projectName now) store
                        |> Tuple.second
                )
                (\_ -> store)


nameEquals name =
    getName >> equals name


setId : Id -> ModelF
setId id model =
    { model | id = id }


updateId : (Model -> Id) -> ModelF
updateId updater model =
    setId (updater model) model


getRev : Model -> PouchDB.Revision
getRev =
    (.rev)


setRev : PouchDB.Revision -> ModelF
setRev rev model =
    { model | rev = rev }


updateRev : (Model -> PouchDB.Revision) -> ModelF
updateRev updater model =
    setRev (updater model) model


getName : Model -> Name
getName =
    (.name)


setName : Name -> ModelF
setName name model =
    { model | name = name }


setDeleted deleted model =
    { model | deleted = deleted }


setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


updateName : (Model -> Name) -> ModelF
updateName updater model =
    setName (updater model) model


constructor id rev createdAt modifiedAt deleted name =
    { id = id
    , rev = rev
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = deleted
    , dirty = False
    , name = name
    }


init : Name -> Time -> Id -> Model
init name now id =
    constructor id "" now now False name


null : Model
null =
    constructor "" "" 0 0 False "<No Project>"


isNull =
    equals null


type alias Encoded =
    E.Value


encode : Project -> Encoded
encode project =
    E.object ((PouchDB.encode project) ++ [ "name" => E.string (getName project) ])


decoder : Decoder Project
decoder =
    D.decode constructor
        |> PouchDB.documentFieldsDecoder
        |> D.required "name" D.string
