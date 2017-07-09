module Todo.Store exposing (..)

import Firebase.Types exposing (DeviceId)
import Random.Pcg as Random
import Todo exposing (..)
import Store
import Todo.Types exposing (TodoStore)


generator : DeviceId -> List Encoded -> Random.Generator TodoStore
generator =
    Store.generator "todo-db" encodeOtherFields decoder
