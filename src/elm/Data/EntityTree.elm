module Data.EntityTree exposing (..)

import Entity.Types exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types.GroupDoc exposing (GroupDoc)
import Types.Todo exposing (TodoDoc)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type Title
    = GroupEntityTitle GroupEntityType
    | StringTitle String


type Node
    = Node Title (List TodoDoc)


type Tree
    = Root Node
    | Forest List Node


initTodoForest stringTitle todoList =
    Root (Node stringTitle todoList)
