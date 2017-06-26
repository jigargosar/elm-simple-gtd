module Todo.Store exposing (..)

import Firebase exposing (DeviceId)
import Random.Pcg as Random

import Todo exposing (..)






import Store


generator : DeviceId -> List Encoded -> Random.Generator Store
generator =
    Store.generator "todo-db" encodeOtherFields decoder
