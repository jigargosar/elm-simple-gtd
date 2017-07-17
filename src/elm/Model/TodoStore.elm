module Model.TodoStore exposing (..)

import Store
import X.Record


todoStore =
    X.Record.fieldLens .todoStore (\s b -> { b | todoStore = s })


focusInEntity =
    X.Record.fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })



--findTodoById : DocId -> AppModel -> Maybe TodoDoc


findTodoById id =
    .todoStore >> Store.findById id
