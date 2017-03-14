module Todos exposing (..)

import Random.Pcg as Random exposing (Seed)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Todo =
    { id : String, text : String }


type alias Todos =
    { todos : List Todo
    , seed : Seed
    }


type TodosModel
    = TodosModel Todos


todoModelGenerator : Random.Generator TodosModel
todoModelGenerator =
    Random.map initWithSeed Random.independentSeed


initWithSeed seed =
    TodosModel (Todos [] seed)
