module Model.TodoStore exposing (..)

import Document.Types exposing (DocId)
import Store
import Todo
import Todo.Types exposing (TodoDoc)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record


todoStore =
    X.Record.fieldLens .todoStore (\s b -> { b | todoStore = s })


focusInEntity =
    X.Record.fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })


findTodoById : DocId -> AppModel -> Maybe TodoDoc
findTodoById id =
    .todoStore >> Store.findById id
