module Document exposing (..)

import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


getId =
    .id


hasId id =
    getId >> equals id


equalById doc1 doc2 =
    getId doc1 == getId doc2


type alias Id =
    String


type alias Revision =
    String


defaultRevision =
    ""


type alias Meta =
    { id : Id
    , rev : Revision
    , dirty : Bool
    , deleted : Bool
    , createdAt : Time
    , modifiedAt : Time
    }


type alias Document moreFields =
    { moreFields
        | id : Id
        , rev : Revision
        , dirty : Bool
        , deleted : Bool
        , createdAt : Time
        , modifiedAt : Time
    }


encodeMetaFields doc =
    [ "_id" => E.string (doc.id)
    , "_rev" => E.string (doc.rev)
    , "createdAt" => E.int (doc.createdAt |> round)
    , "modifiedAt" => E.int (doc.modifiedAt |> round)
    , "deleted" => E.bool (doc.deleted)
    ]


encode encodeOtherFields doc =
    E.object
        (encodeMetaFields doc
            ++ encodeOtherFields doc
        )


documentFieldsDecoder : Decoder (Id -> Revision -> Time -> Time -> Bool -> x) -> Decoder x
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.required "_rev" D.string
        >> D.optional "createdAt" (D.float) 0
        >> D.optional "modifiedAt" (D.float) 0
        >> D.optional "deleted" D.bool False


isDeleted =
    .deleted


setDeleted deleted model =
    { model | deleted = deleted }


setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


toggleDeleted model =
    { model | deleted = not model.deleted }



--type alias TT msg =
--    Tracker {} {} msg
--
--
--createTracker : TT msg
--createTracker =
--    Port.init (\req -> ping req)
--
--
--port ping : { portRequestId : Int } -> Cmd msg
--
--
--port pong : ({ portRequestId : Int } -> msg) -> Sub msg
--
--
--tt =
--    createTracker
--
--
--test : ( TT msg, Cmd msg )
--test =
--    Port.call { portRequestId = 0 } (\res -> Cmd.none) tt
