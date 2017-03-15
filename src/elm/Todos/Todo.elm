module Todos.Todo exposing (..)

import Json.Encode as E
import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import FunctionalHelpers exposing (..)


type alias TodoId =
    String


type alias Todo =
    { text : String, id : TodoId }


encode : Todo -> E.Value
encode todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "text" => E.string (getText todo)
        ]


create =
    Todo


todoGenerator text =
    Random.map (Todo text) RandomIdGenerator.idGen


getText =
    (.text)


setText text todo =
    { todo | text = text }


getId =
    (.id)


equalById todo1 todo2 =
    getId todo1 == getId todo2


isTextEmpty todo =
    getText todo |> String.trim |> String.isEmpty
