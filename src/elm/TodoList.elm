module TodoList exposing (..)

import PouchDB
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todo
import TodoList.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Todo.Types exposing (EncodedTodo, Todo, TodoId)
import Ext.Random as Random


decodeList : List EncodedTodo -> List Todo
decodeList =
    List.map (D.decodeValue Todo.todoDecoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok todo ->
                        Just todo

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding todo" x
                        in
                            Nothing
            )


maybeTuple2With f model =
    f model ?|> (,) # model


insertCopy : Todo -> Time -> TodoStore -> TodoStore
insertCopy todo now =
    PouchDB.insert (Todo.copyGenerator now todo)


insertNew : String -> Time -> TodoStore -> TodoStore
insertNew text now =
    PouchDB.insert (Todo.todoGenerator now text)


init : List Todo -> Seed -> TodoStore
init =
    PouchDB.init "todo-db" Todo.encode


generator : List EncodedTodo -> Random.Generator TodoStore
generator =
    decodeList >> init >> Random.mapWithIndependentSeed
