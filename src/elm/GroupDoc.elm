module GroupDoc exposing (..)

import Document
import Ext.Predicate
import Ext.Record
import Firebase exposing (DeviceId)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Store
import Tuple2


type alias Name =
    String


type alias Record =
    { name : Name
    , archived : Bool
    }


archived =
    Ext.Record.bool .archived (\s b -> { b | archived = s })


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
    -> Model
constructor id rev createdAt modifiedAt deleted deviceId name =
    { id = id
    , rev = rev
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = False
    , archived = deleted
    , deviceId = deviceId
    , name = name
    }


toggleArchived =
    Ext.Record.toggle archived


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
    in
        tuple
            |> Tuple2.mapBoth Document.isDeleted
            |> (\deletedTuple ->
                    case deletedTuple of
                        ( True, False ) ->
                            GT

                        ( False, True ) ->
                            LT

                        ( True, True ) ->
                            compareName tuple

                        ( False, False ) ->
                            compareName tuple
               )


activeFilter =
    Ext.Predicate.all [ Document.isNotDeleted, isNotArchived ]


archivedFilter =
    Ext.Predicate.all [ Document.isNotDeleted, isArchived ]
