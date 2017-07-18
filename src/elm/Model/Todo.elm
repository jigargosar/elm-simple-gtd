module Model.Todo exposing (..)

import Store
import X.Record


todoStore =
    X.Record.fieldLens .todoStore (\s b -> { b | todoStore = s })



--findTodoById : DocId -> AppModel -> Maybe TodoDoc


findTodoById id =
    .todoStore >> Store.findById id
