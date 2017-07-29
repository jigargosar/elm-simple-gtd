module GroupDoc exposing (..)

import Document exposing (DocId)
import Firebase.Types exposing (DeviceId)
import GroupDoc.Types exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg
import Store
import Time exposing (Time)
import Tuple2
import X.Function.Infix exposing (..)
import X.Predicate
import X.Record


createGroupDocIdFromType gdType =
    case gdType of
        ContextGroupDocType ->
            ContextGroupDocId

        ProjectGroupDocType ->
            ProjectGroupDocId


getGroupDocName =
    .name


isGroupDocArchived =
    .archived


archived =
    X.Record.bool .archived (\s b -> { b | archived = s })


constructor :
    DocId
    -> Document.Revision
    -> Time
    -> Time
    -> Document.Deleted
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


sort isNull =
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
