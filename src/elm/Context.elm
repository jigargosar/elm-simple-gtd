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


type alias Name =
    String


type alias Record =
    { name : Name }


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
    , deleted = deleted
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
    constructor "" "" 0 0 False "" "Inbox"


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
                    compare (getName v1) (getName v2)
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
