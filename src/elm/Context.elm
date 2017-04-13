module Context exposing (..)

import Dict
import Document
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
    { name : Name }


type alias Model =
    PouchDB.Document Record


type alias Store =
    PouchDB.Store Record


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
encoder context =
    E.object
        ((PouchDB.encode context)
            ++ [ "name" => E.string context.name
               ]
        )


decoder : Decoder Model
decoder =
    D.decode constructor
        |> PouchDB.documentFieldsDecoder
        |> D.required "name" D.string


null : Model
null =
    constructor "" "" 0 0 False "Inbox"


isNull =
    equals null


getName =
    .name


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
    PouchDB.map (apply2 ( Document.getId, identity )) >> Dict.fromList


findNameById id =
    PouchDB.findById id >>? getName


findByName name =
    PouchDB.findBy (getName >> equals (String.trim name))


getEncodedNames =
    PouchDB.map (.name >> E.string) >> E.list
