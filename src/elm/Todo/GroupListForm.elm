module Todo.GroupListForm exposing (..)

import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { todo : Todo.Model
    , maybeFocusKey : Maybe String
    }


init todo =
    { todo = todo, maybeFocusKey = Nothing }


setMaybeFocusKey maybeFocusKey form =
    { form | maybeFocusKey = maybeFocusKey }
