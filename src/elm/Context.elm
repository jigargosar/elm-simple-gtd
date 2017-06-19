module Context exposing (..)

import Dict
import Document exposing (Document, Id, Revision)
import Firebase exposing (DeviceId)
import Store
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Random.Pcg as Random
import String.Extra
import Time exposing (Time)
import Tuple2


type alias Name =
    String


type alias Record =
    { name : Name
    , archived : Bool
    }


type alias Model =
    Document.Document Record


type alias Store =
    Store.Store Record


type alias Encoded =
    E.Value


constructor : Id -> Revision -> Time -> Time -> Bool -> DeviceId -> Name -> Model
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


init : Name -> Time -> DeviceId -> Id -> Model
init name now deviceId id =
    constructor id "" now now False deviceId name


otherFieldsEncoder : Document Record -> List ( String, E.Value )
otherFieldsEncoder project =
    [ "name" => E.string (getName project) ]


decoder : Decoder Model
decoder =
    D.decode constructor
        |> Document.documentFieldsDecoder
        |> D.required "name" D.string


null : Model
null =
    constructor nullId "" 0 0 False "" "Inbox"


nullId =
    ""


isNullId =
    equals nullId


filterNull pred =
    [ null ] |> List.filter pred


sort =
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


isNull =
    equals null


getName =
    .name


setName name model =
    { model | name = name }


storeGenerator : DeviceId -> List Encoded -> Random.Generator Store
storeGenerator =
    Store.generator "context-db" otherFieldsEncoder decoder


findNameById id =
    Store.findById id >>? getName


findByName name =
    Store.findBy (getName >> equals (String.trim name))
