module GroupDoc exposing (..)

import Data.DeviceId exposing (DeviceId)
import Document exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg
import Store exposing (..)
import Time exposing (Time)
import Tuple2
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Predicate
import X.Record


type GroupDocType
    = ContextGroupDocType
    | ProjectGroupDocType


type GroupDocId
    = GroupDocId GroupDocType DocId


contextIdFromDocId =
    GroupDocId ContextGroupDocType


projectIdFromDocId =
    GroupDocId ProjectGroupDocType


contextIdFromDoc =
    Document.getId >> contextIdFromDocId


idFromDoc gdType gdDoc =
    GroupDocId gdType (Document.getId gdDoc)


projectIdFromDoc =
    Document.getId >> projectIdFromDocId


type GroupDocAction
    = GDA_StartAdding


type GroupDocIdAction
    = GDA_StartEditing
    | GDA_ToggleArchived
    | GDA_ToggleDeleted
    | GDA_UpdateFormName GroupDocForm GroupDocName
    | GDA_SaveForm GroupDocForm


type alias GroupDocForm =
    { id : DocId
    , groupDocType : GroupDocType
    , groupDocId : GroupDocId
    , name : GroupDocName
    , isArchived : Bool
    , mode : GroupDocFormMode
    }


type GroupDocFormMode
    = GDFM_Add
    | GDFM_Edit


type alias GroupDocName =
    String


type alias Archived =
    Bool


type alias Record =
    { name : GroupDocName
    , archived : Bool
    }


type alias GroupDoc =
    Document Record


type alias ContextDoc =
    GroupDoc


type alias ProjectDoc =
    GroupDoc


type alias GroupDocStore =
    Store Record


type alias ProjectStore =
    GroupDocStore


type alias ContextStore =
    GroupDocStore


getGroupDocName =
    .name


isGroupDocArchived =
    .archived


archived =
    X.Record.bool .archived (\s b -> { b | archived = s })


constructor :
    DocId
    -> Revision
    -> Time
    -> Time
    -> Deleted
    -> DeviceId
    -> GroupDocName
    -> Archived
    -> GroupDoc
constructor id rev createdAt modifiedAt deleted deviceId name archived =
    { id = id
    , rev = rev
    , deviceId = deviceId
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = False
    , archived =
        if deleted then
            True
        else
            archived
    , name = name
    }


init : GroupDocName -> Time -> DeviceId -> DocId -> GroupDoc
init name now deviceId id =
    constructor id "" now now False deviceId name False


decoder : Decoder GroupDoc
decoder =
    D.decode constructor
        |> Document.documentFieldsDecoder
        |> D.required "name" D.string
        |> D.optional "archived" D.bool False


encodeRecordFields : GroupDoc -> List ( String, E.Value )
encodeRecordFields model =
    [ "name" => E.string model.name
    , "archived" => E.bool model.archived
    ]


storeGenerator : String -> DeviceId -> List E.Value -> Random.Pcg.Generator GroupDocStore
storeGenerator dbName =
    Store.generator dbName encodeRecordFields decoder


toggleArchived =
    X.Record.toggle archived


getName =
    .name


isArchived =
    .archived


isNotArchived =
    isArchived >> not


sortWithIsNull isNull =
    List.sortWith
        (\v1 v2 ->
            case ( isNull v1, isNull v2 ) of
                ( True, False ) ->
                    LT

                ( False, True ) ->
                    GT

                ( True, True ) ->
                    EQ

                ( False, False ) ->
                    compareNotNulls ( v1, v2 )
        )


sort : List GroupDoc -> List GroupDoc
sort =
    List.sortWith ((,) >>> compareNotNulls)


compareNotNulls tuple =
    let
        compareName =
            Tuple2.mapBoth getName >> uncurry compare

        compareModifiedAt =
            Tuple2.mapBoth (Document.getModifiedAt >> negate) >> uncurry compare
    in
    tuple
        |> Tuple2.mapBoth isArchived
        |> (\archivedTuple ->
                case archivedTuple of
                    ( True, False ) ->
                        LT

                    ( False, True ) ->
                        GT

                    ( True, True ) ->
                        compareModifiedAt tuple

                    ( False, False ) ->
                        compareName tuple
           )


isActive =
    X.Predicate.all [ Document.isNotDeleted, isNotArchived ]


archivedButNotDeletedPred =
    X.Predicate.all [ Document.isNotDeleted, isArchived ]


setName name model =
    { model | name = name }


nullProject : GroupDoc
nullProject =
    let
        nullId =
            ""
    in
    constructor nullId "" 0 0 False "" "No Project" False


filterNullProject pred =
    [ nullProject ] |> List.filter pred


isNullProject =
    equals nullProject


sortProjects =
    sortWithIsNull isNullProject


projectStoreGenerator : DeviceId -> List E.Value -> Random.Pcg.Generator ProjectStore
projectStoreGenerator =
    storeGenerator "project-db"


nullContext : GroupDoc
nullContext =
    let
        nullContextId =
            ""
    in
    constructor nullContextId "" 0 0 False "" "Inbox" False


filterNullContext pred =
    [ nullContext ] |> List.filter pred


sortContexts =
    sortWithIsNull isNullContext


isNullContext =
    equals nullContext


contextStoreGenerator : DeviceId -> List E.Value -> Random.Pcg.Generator ContextStore
contextStoreGenerator =
    storeGenerator "context-db"
