module GroupDoc exposing (..)

import Document
import X.Predicate
import X.Record
import Firebase exposing (DeviceId)
import Time exposing (Time)



import X.Function.Infix exposing (..)


import Store
import Tuple2
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg


type alias Name =
    String


type alias Archived =
    Bool


type alias Record =
    { name : Name
    , archived : Bool
    }


archived =
    X.Record.bool .archived (\s b -> { b | archived = s })


type alias Model =
    Document.Document Record


constructor :
    Document.Id
    -> Document.Revision
    -> Time
    -> Time
    -> Document.Deleted
    -> DeviceId
    -> Name
    -> Archived
    -> Model
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


decoder : Decoder Model
decoder =
    D.decode constructor
        |> Document.documentFieldsDecoder
        |> D.required "name" D.string
        |> D.optional "archived" D.bool False


encodeRecordFields : Model -> List ( String, E.Value )
encodeRecordFields model =
    [ "name" => E.string model.name
    , "archived" => E.bool model.archived
    ]


storeGenerator : String -> DeviceId -> List E.Value -> Random.Pcg.Generator Store
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


type alias Store =
    Store.Store Record


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
