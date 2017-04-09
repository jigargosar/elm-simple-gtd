module Project exposing (..)

import Dict
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


type alias OtherFields =
    PouchDB.HasTimeStamps { name : Name }


type alias Project =
    PouchDB.Document OtherFields


type alias Model =
    Project


type alias ModelF =
    Model -> Model


type alias Name =
    String


type alias Id =
    PouchDB.Id


type alias Store =
    PouchDB.Store OtherFields


getEncodedProjectNames =
    PouchDB.map (getName >> E.string) >> E.list


getProjectIdToNameDict =
    PouchDB.map (apply2 ( getId, getName )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? getName


storeGenerator : List Encoded -> Random.Generator Store
storeGenerator =
    PouchDB.generator "project-db" encode decoder


findByName projectName =
    PouchDB.findBy (nameEquals (String.trim projectName))


insertIfNotExistByName projectName now m =
    if (String.Extra.isBlank projectName) then
        m
    else
        findByName projectName m
            |> Maybe.Extra.unpack
                (\_ ->
                    PouchDB.insert (init projectName now) m
                        |> Tuple.second
                )
                (\_ -> m)


nameEquals name =
    getName >> equals name


idEquals id =
    getId >> equals id


getId : Model -> Id
getId =
    (.id)


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


updateName : (Model -> Name) -> ModelF
updateName updater model =
    setName (updater model) model


projectConstructor id rev createdAt modifiedAt name =
    { id = id
    , rev = rev
    , dirty = False
    , name = name
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


init name now id =
    projectConstructor id "" now now name


type alias Encoded =
    E.Value


encode : Project -> Encoded
encode project =
    E.object
        [ "_id" => E.string (getId project)
        , "_rev" => E.string (getRev project)
        , "name" => E.string (getName project)
        , "createdAt" => E.int (project.createdAt |> round)
        , "modifiedAt" => E.int (project.modifiedAt |> round)
        ]


decoder : Decoder Project
decoder =
    D.decode projectConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> D.required "name" D.string
