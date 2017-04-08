module Context exposing (..)

import PouchDB
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias ContextName =
    String


type alias ContextRecord =
    { name : ContextName }


type alias OtherFields =
    PouchDB.HasTimeStamps ContextRecord


type alias Context =
    PouchDB.Document OtherFields


type alias Store =
    PouchDB.Store OtherFields


type alias Encoded =
    E.Value


constructor id rev createdAt modifiedAt name =
    { id = id
    , rev = rev
    , dirty = False
    , name = name
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


encode : Context -> Encoded
encode context =
    E.object
        [ "_id" => E.string context.id
        , "_rev" => E.string context.rev
        , "name" => E.string context.name
        , "createdAt" => E.int (context.createdAt |> round)
        , "modifiedAt" => E.int (context.modifiedAt |> round)
        ]


decoder : Decoder Context
decoder =
    D.decode constructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> D.required "name" D.string
