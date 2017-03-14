module Main.Model exposing (..)

import Return
import Todos exposing (TodosModel)


type alias Model =
    { todosModel : TodosModel }


init =
    { todosModel = Todos.init }
