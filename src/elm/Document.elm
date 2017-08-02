module Document exposing (..)

import Data.DeviceId exposing (DeviceId)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Time exposing (Time)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias DocId =
    String


type alias Revision =
    String


type alias Deleted =
    Bool


type alias Document record =
    { record
        | id : DocId
        , rev : Revision
        , deleted : Deleted
        , createdAt : Time
        , modifiedAt : Time
        , deviceId : DeviceId
    }


getId =
    .id


hasId id =
    getId >> equals id


equalById doc1 doc2 =
    getId doc1 == getId doc2


type alias DocF record =
    Document record -> Document record


defaultRevision =
    ""


encodeModel doc =
    [ "_id" => E.string doc.id
    , "_rev" => E.string doc.rev
    , "createdAt" => E.int (doc.createdAt |> round)
    , "modifiedAt" => E.int (doc.modifiedAt |> round)
    , "deleted" => E.bool doc.deleted
    , "deviceId" => E.string doc.deviceId
    ]


encode encodeRecord doc =
    E.object
        (encodeModel doc
            ++ encodeRecord doc
        )


documentFieldsDecoder :
    Decoder (DocId -> Revision -> Time -> Time -> Bool -> DeviceId -> record)
    -> Decoder record
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.optional "_rev" D.string defaultRevision
        >> D.optional "createdAt" D.float 0
        >> D.optional "modifiedAt" D.float 0
        >> D.optional "deleted" D.bool False
        >> D.optional "deviceId" D.string ""


isDeleted =
    .deleted


isNotDeleted =
    isDeleted >> not


getModifiedAt =
    .modifiedAt


setDeleted deleted model =
    { model | deleted = deleted }


setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


setDeviceId deviceId model =
    { model | deviceId = deviceId }


toggleDeleted model =
    { model | deleted = not model.deleted }
