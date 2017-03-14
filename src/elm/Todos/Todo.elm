module Todos.Todo exposing (..)

import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)


type alias Todo =
    { text : String, id : String }


create =
    Todo
