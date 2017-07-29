module Todo.Store exposing (..)

import Random.Pcg as Random
import Store
import Todo exposing (..)
import Types.Firebase exposing (..)
import Types.Todo exposing (..)


generator : DeviceId -> List Encoded -> Random.Generator TodoStore
generator =
    Store.generator "todo-db" encodeOtherFields decoder
