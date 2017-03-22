module TodoStore exposing (..)

import Dict
import Dict.Extra as Dict
import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todo as Todo exposing (Todo, TodoId, TodoList)
import TodoStore.Update
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import FunctionExtra exposing (..)
import TodoStore.Model as Model exposing (Model)
import Tuple2
import Function exposing ((>>>>))
import PouchDB


type alias TodoStore =
    Model.Model


getInbox__ : TodoStore -> TodoList
getInbox__ =
    Model.getInboxTodoList


getFirstInboxTodo =
    Model.getFirstInboxTodo



-- external


generator =
    Model.generator


deleteTodo =
    Model.deleteTodo


replaceTodoIfIdMatches =
    Model.replaceTodoIfIdMatches


addNewTodo =
    Model.addNewTodo


update =
    TodoStore.Update.update


deleteAction =
    Model.Delete

toggleDoneAction =
    Model.ToggleDone


doneAction =
    Model.Done


editTodo : Model.Action -> TodoId -> Model -> ( Model, Cmd msg )
editTodo =
    Model.editTodo >>>> Tuple.mapSecond persistMaybeTodoCmd


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none persistTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
