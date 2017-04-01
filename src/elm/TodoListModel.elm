module TodoListModel exposing (..)

import Todo
import TodoListModel.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


decodeTodoList : EncodedTodoList -> TodoListModel
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
