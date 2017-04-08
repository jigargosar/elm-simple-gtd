module Context exposing (..)

import Dict
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
import Random.Pcg as Random
import String.Extra


type alias Name =
    String


type alias Id =
    PouchDB.Id


type alias Record =
    { name : Name }


type alias OtherFields =
    PouchDB.HasTimeStamps Record


type alias Model =
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


init name now id =
    constructor id "" now now name


encoder : Model -> Encoded
encoder context =
    E.object
        [ "_id" => E.string context.id
        , "_rev" => E.string context.rev
        , "name" => E.string context.name
        , "createdAt" => E.int (context.createdAt |> round)
        , "modifiedAt" => E.int (context.modifiedAt |> round)
        ]


decoder : Decoder Model
decoder =
    D.decode constructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> D.required "name" D.string


getName =
    .name


getId =
    .id


storeGenerator : List Encoded -> Random.Generator Store
storeGenerator =
    PouchDB.generator "context-db" encoder decoder


insertIfNotExistByName name now context =
    if (String.Extra.isBlank name) then
        context
    else
        findByName name context
            |> Maybe.unpack
                (\_ ->
                    PouchDB.insert (init name now) context
                        |> Tuple.second
                )
                (\_ -> context)


byIdDict =
    PouchDB.map (apply2 ( .id, identity )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? getName


findByName name =
    PouchDB.findBy (getName >> equals (String.trim name))


getEncodedNames =
    PouchDB.map (.name >> E.string) >> E.list
