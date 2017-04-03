module TodoList exposing (..)

import Random.Pcg as Random
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
import Todo.Types exposing (Todo, TodoId)


decodeTodoList : EncodedTodoList -> TodoList
decodeTodoList =
    List.map (D.decodeValue Todo.todoDecoder)
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


findById id =
    List.find (Todo.hasId id)


maybeTuple2With f model =
    f model ?|> (,) # model


createMaybeCopyGeneratorOfTodoWithId : TodoId -> Time -> TodoList -> Maybe (Random.Generator Todo)
createMaybeCopyGeneratorOfTodoWithId todoId now =
    findById todoId >>? Todo.copyGenerator now
