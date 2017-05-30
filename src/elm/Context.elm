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


constructor : Id -> Revision -> Time -> Time -> Bool -> Name -> Model
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


storeGenerator : DeviceId -> List Encoded -> Random.Generator Store
storeGenerator =
    Store.generator "context-db" otherFieldsEncoder decoder


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
                        Store.insert (init name now) context
                            |> Tuple.second
                    )
                    (\_ -> context)


findNameById id =
    Store.findById id >>? getName


findByName name =
    Store.findBy (getName >> equals (String.trim name))


getEncodedNames =
    Store.map (.name >> E.string) >> E.list
