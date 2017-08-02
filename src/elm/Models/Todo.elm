module Models.Todo exposing (..)

import Store
import X.Record exposing (..)


todoStore =
    fieldLens .todoStore (\s b -> { b | todoStore = s })


findTodoById id =
    .todoStore >> Store.findById id


isStoreEmpty =
    .todoStore >> Store.isEmpty
