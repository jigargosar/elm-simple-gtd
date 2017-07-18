module Stores exposing (..)

import Document
import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityId
import Model exposing (focusInEntity)
import Model.EntityTree
import Model.GroupDocStore exposing (..)
import Model.Stores
import Model.Todo exposing (..)
import Model.ViewType
import Return exposing (andThen)
import Store
import Todo
import Todo.Types exposing (TodoAction(TA_AutoSnooze), TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (maybeOverT2, maybeSetIn, overT2, set, setIn)
import Set
import Tuple2
import X.List


_ =
    1
