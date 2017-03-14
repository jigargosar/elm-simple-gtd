module Todos exposing (..)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Todo =
    { id : String, text : String }


type alias Todos =
    { todos : List Todo }


type TodosModel
    = TodosModel Todos


init =
    TodosModel { todos = [] }
