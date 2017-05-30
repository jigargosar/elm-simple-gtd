module Todo.Store exposing (..)

import Random.Pcg as Random
import Set
import Todo exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Store


generator : List Encoded -> Random.Generator Store
generator =
    Store.generator "todo-db" encodeOtherFields decoder


update action now todoId store =
    Store.updateAllDocs (Set.singleton todoId)
        now
        (Todo.update [ action ] now)
        store
