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
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Time exposing (Time)


type alias TodoId =
    String


type alias Todo =
    { text : String
    , dueAt : Maybe Time
    , deleted : Bool
    , rev : String
    , id : TodoId
    }


todoConstructor id rev text dueAt deleted =
    Todo text dueAt deleted rev id


decoder : Decoder Todo
decoder =
    D.decode todoConstructor
        |> D.required "_id" D.string
        |> D.required "_rev" D.string
        |> D.required "text" D.string
        |> D.optional "dueAt" (D.maybe D.float) Nothing
        |> D.optional "deleted" D.bool False


createWithTextAndId text id =
    Todo text Nothing False "" id


type alias EncodedTodo =
    E.Value


type alias EncodedTodoList =
    List EncodedTodo


encode : Todo -> EncodedTodo
encode todo =
    E.object
        [ "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (isDeleted todo)
        , "_rev" => E.string (getRev todo)
        , "_id" => E.string (getId todo)
        ]


encodeSingleton : Todo -> EncodedTodoList
encodeSingleton todo =
    [ encode todo ]


decodeValue =
    D.decodeValue decoder


decodeTodoList : EncodedTodoList -> List Todo
decodeTodoList =
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


isDeleted =
    (.deleted)


setText text todo =
    { todo | text = text }


getId =
    (.id)


markDeleted todo =
    { todo | deleted = True }


equalById todo1 todo2 =
    getId todo1 == getId todo2


isTextEmpty todo =
    getText todo |> String.trim |> String.isEmpty


hasId todoId =
    getId >> equals todoId


fromListById =
    Dict.fromListBy getId


replaceIfEqualById todo =
    List.replaceIf (equalById todo) todo
