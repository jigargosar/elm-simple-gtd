module Main.Msg exposing (..)

import Json.Decode
import Navigation exposing (Location)
import Todos.Todo exposing (TodoId)


type Msg
    = LocationChanged Location
    | OnAddTodo
    | OnDeleteTodo TodoId
    | OnEditTodo TodoId
