module Todo.TimeTracker exposing (..)

import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias ModelRec =
    { todoId : Todo.Id
    , startedAt : Time
    }


type alias Model =
    Maybe ModelRec


init : Model
init =
    Nothing


start todoId now =
    { todoId = todoId
    , startedAt = now
    }
