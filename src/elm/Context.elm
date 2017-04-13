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
import Time exposing (Time)


type alias Name =
    String


type alias Id =
    PouchDB.Id


type alias Record =
    { name : Name, deleted : Bool }


type alias OtherFields =
    PouchDB.HasTimeStamps Record


type alias Model =
    PouchDB.Document OtherFields


type alias Store =
    PouchDB.Store OtherFields


type alias Encoded =
    E.Value


constructor : Id -> PouchDB.Revision -> Time -> Time -> Bool -> Name -> Model
constructor id rev createdAt modifiedAt deleted name =
    { id = id
    , rev = rev
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , dirty = False
    , deleted = deleted
    , name = name
    }


init name now id =
    constructor id "" now now False name


encoder : Model -> Encoded
encoder model =
    E.object
        [ "_id" => E.string model.id
        , "_rev" => E.string model.rev
        , "name" => E.string model.name
        , "deleted" => E.bool model.deleted
        , "createdAt" => E.int (model.createdAt |> round)
        , "modifiedAt" => E.int (model.modifiedAt |> round)
        ]


decoder : Decoder Model
decoder =
    D.decode constructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> D.optional "deleted" D.bool False
        |> D.required "name" D.string


null : Model
null =
    constructor "" "" 0 0 False "Inbox"


isNull =
    equals null


getName =
    .name


getId =
    .id


setName name model =
    { model | name = name }


setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


setDeleted deleted model =
    { model | deleted = deleted }


storeGenerator : List Encoded -> Random.Generator Store
storeGenerator =
    PouchDB.generator "context-db" encoder decoder


insertIfNotExistByName name_ now context =
    let
        name =
            String.trim name_
    in
        if (String.isEmpty name || String.toLower name == "inbox") then
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
