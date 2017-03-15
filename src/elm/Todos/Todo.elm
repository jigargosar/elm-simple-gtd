module Todos.Todo exposing (..)

import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)

type alias TodoId = String

type alias Todo =
    { text : String, id : TodoId }


create =
    Todo


todoGenerator text =
    Random.map (Todo text) RandomIdGenerator.idGen


getText =
    (.text)

setText text todo=
    {todo| text=text}


getId =
    (.id)
