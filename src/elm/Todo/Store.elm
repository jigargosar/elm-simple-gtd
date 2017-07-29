module Todo.Store exposing (..)

import Random.Pcg as Random
import Store
import Todo exposing (..)
import Todo.Types exposing (TodoStore)
import Types.Firebase exposing (..)


generator : DeviceId -> List Encoded -> Random.Generator TodoStore
generator =
    Store.generator "todo-db" encodeOtherFields decoder
