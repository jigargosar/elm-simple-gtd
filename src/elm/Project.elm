module Project exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Random.Pcg as Random exposing (..)
import RandomIdGenerator
import Json.Decode as D exposing (Decoder)
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
    PouchDB.Id


nameEquals name =
    getName >> equals name


getId : Model -> ProjectId
getId =
    (.id)


setId : ProjectId -> ModelF
setId id model =
    { model | id = id }


updateId : (Model -> ProjectId) -> ModelF
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


projectConstructor id rev createdAt modifiedAt name =
    { id = id
    , rev = rev
    , name = name
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


projectGenerator name now =
    let
        createWithId id =
            projectConstructor id "" now now name
    in
        Random.map createWithId RandomIdGenerator.idGen


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


decoder : Decoder Project
decoder =
    D.decode projectConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> D.required "name" D.string


decodeProjectList : EncodedProjectList -> ProjectList
decodeProjectList =
    List.map (D.decodeValue decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok todo ->
                        Just todo

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding todo"
                        in
                            Nothing
            )
