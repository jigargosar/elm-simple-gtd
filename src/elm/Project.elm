module Project exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Random.Pcg as Random exposing (..)
import RandomIdGenerator
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias Project =
    PouchDB.Document (PouchDB.WithTimeStamps { name : ProjectName })


type alias Model =
    Project


type alias ModelF =
    Model -> Model


type alias ProjectList =
    List Project


type alias ProjectName =
    String


type alias ProjectId =
    String


nameEquals name =
    getName >> equals name


getId : Model -> PouchDB.Id
getId =
    (.id)


setId : PouchDB.Id -> ModelF
setId id model =
    { model | id = id }


updateId : (Model -> PouchDB.Id) -> ModelF
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


getName : Model -> ProjectName
getName =
    (.name)


setName : ProjectName -> ModelF
setName name model =
    { model | name = name }


updateName : (Model -> ProjectName) -> ModelF
updateName updater model =
    setName (updater model) model


initWithNameAndId name now id =
    { id = id, rev = "", name = name, createdAt = now, modifiedAt = now }


projectGenerator name now =
    Random.map (initWithNameAndId name now) RandomIdGenerator.idGen


type alias EncodedProject =
    E.Value


type alias EncodedProjectList =
    List EncodedProject


encode : Project -> EncodedProject
encode project =
    E.object
        [ "_id" => E.string (getId project)
        , "_rev" => E.string (getRev project)
        , "name" => E.string (getName project)
        , "createdAt" => E.int (project.createdAt |> round)
        , "modifiedAt" => E.int (project.modifiedAt |> round)
        ]


encodeSingleton : Project -> EncodedProjectList
encodeSingleton =
    encode >> List.singleton
