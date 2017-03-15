module Todos.Todo exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import FunctionalHelpers exposing (..)
import Result.Extra as Result
import Dict.Extra as Dict
import Time exposing (Time)


type alias TodoId =
    String


type alias Todo =
    { text : String
    , dueAt : Maybe Time
    , rev : String
    , id : TodoId
    }


createWithTextAndId text id =
    Todo text Nothing "" id


encode : Todo -> E.Value
encode todo =
    E.object
        [ "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "_rev" => E.string (getRev todo)
        , "_id" => E.string (getId todo)
        ]


decoder : Decoder Todo
decoder =
    D.succeed Todo
        |> D.required "text" D.string
        |> D.optional "dueAt" (D.maybe D.float) Nothing
        |> D.required "_rev" D.string
        |> D.required "_id" D.string


decodeValue =
    D.decodeValue decoder


decodeList : List D.Value -> List Todo
decodeList =
    List.map decodeValue
        >> List.filterMap
            (\result ->
                case result of
                    Ok todo ->
                        Just todo

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding todo"
                        in
                            Nothing
            )


todoGenerator text =
    Random.map (createWithTextAndId text) RandomIdGenerator.idGen


getText =
    (.text)


getDueAt =
    (.dueAt)


getRev =
    (.rev)


setText text todo =
    { todo | text = text }


getId =
    (.id)


equalById todo1 todo2 =
    getId todo1 == getId todo2


isTextEmpty todo =
    getText todo |> String.trim |> String.isEmpty


fromListById =
    Dict.fromListBy getId
