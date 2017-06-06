module Todo.ProjectsForm exposing (..)

import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { todo : Todo.Model
    , maybeFocusIndex : Maybe Int
    }


init todo =
    { todo = todo, maybeFocusIndex = Nothing }


setFocusIndex index form =
    { form | maybeFocusIndex = Just index }
