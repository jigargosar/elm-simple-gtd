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


encodeMeta meta =
    E.object
        [ "_id" => E.string (meta.id)
        , "_rev" => E.string (meta.rev)
        , "createdAt" => E.int (meta.createdAt |> round)
        , "modifiedAt" => E.int (meta.modifiedAt |> round)
        , "deleted" => E.bool (meta.deleted)
        ]


encode doc otherEncodedFieldList =
    E.object
        ([ "meta" => encodeMeta doc
         ]
            ++ otherEncodedFieldList
        )


documentFieldsDecoder : Decoder (Id -> Revision -> Time -> Time -> Bool -> otherFields) -> Decoder otherFields
documentFieldsDecoder =
    D.required "_id" D.string
        >> D.required "_rev" D.string
        >> D.optional "createdAt" (D.float) 0
        >> D.optional "modifiedAt" (D.float) 0
        >> D.optional "deleted" D.bool False



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
