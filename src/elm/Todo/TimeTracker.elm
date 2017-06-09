module Todo.TimeTracker exposing (..)

import Material
import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type State
    = Running Time
    | Paused


type alias ModelRec =
    { todoId : Todo.Id
    , totalTime : Time
    , state : State
    }


type alias Model =
    Maybe ModelRec


init : Model
init =
    Nothing


wrap =
    Just


start : Todo.Id -> Time -> Model
start todoId now =
    { todoId = todoId
    , totalTime = 0
    , state = Running now
    }
        |> wrap
