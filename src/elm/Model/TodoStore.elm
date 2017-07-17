module Model.TodoStore exposing (..)

import Document.Types exposing (DocId)
import Store
import Todo.Types exposing (TodoDoc)
import X.Record


todoStore =
    X.Record.fieldLens .todoStore (\s b -> { b | todoStore = s })


focusInEntity =
    X.Record.fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })



--findTodoById : DocId -> AppModel -> Maybe TodoDoc


findTodoById id =
    .todoStore >> Store.findById id
