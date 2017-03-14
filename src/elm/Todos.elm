module Todos exposing (..)

import Random.Pcg as Random exposing (Seed)
import Todos.Todo exposing (Todo)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


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
