module TodoList.Types exposing (..)

import PouchDB
import Todo.Types exposing (EncodedTodo, Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


type alias TodoStore =
    PouchDB.Store Todo.Types.OtherFields
