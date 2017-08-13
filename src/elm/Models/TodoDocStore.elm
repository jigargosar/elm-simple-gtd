module Models.TodoDocStore exposing (..)

import Store
import X.Record exposing (..)


todoStoreL =
    fieldLens .todoStore (\s b -> { b | todoStore = s })


filterTodoDocs pred model =
    Store.filterDocs pred model.todoStore


findTodoById id =
    .todoStore >> Store.findById id


isStoreEmpty =
    .todoStore >> Store.isEmpty
