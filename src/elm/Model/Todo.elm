module Model.Todo exposing (..)

--import Todo.Types exposing (TodoDoc, TodoStore)

import Store
import X.Record exposing (..)


--todoStore : Field TodoStore (HasTodoStore a)


todoStore =
    fieldLens .todoStore (\s b -> { b | todoStore = s })



--findTodoById : DocId -> HasTodoStore a -> Maybe TodoDoc


findTodoById id =
    .todoStore >> Store.findById id
