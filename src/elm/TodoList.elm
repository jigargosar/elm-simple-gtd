module TodoList exposing (..)

import Todo
import TodoList.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List
import List.Extra as List
import Dict
import Dict.Extra as Dict


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
