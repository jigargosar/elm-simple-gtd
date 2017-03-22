module TodoList exposing (..)

import List.Extra
import Main.Model exposing (Model)
import Maybe.Extra
import Return exposing (Return, ReturnF)
import Task
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Main.TodoListMsg exposing (..)
import PouchDB
import Tuple2


update : TodoListMsg -> Model -> ( Model, Cmd TodoListMsg )
update msg =
    Return.singleton
        >> case msg of
            UpdateTodoAt action id now ->
                updateAndPersistMaybeTodo (updateTodoWithAction action now id)

            UpdateTodo action id ->
                withNow (UpdateTodoAt action id)


updateAndPersistMaybeTodo updater =
    Return.andThen
        (updater >> Tuple2.mapSecond persistMaybeTodoCmd)


toggleDone =
    UpdateTodo ToggleDone


withNow : (Time -> TodoListMsg) -> ReturnF TodoListMsg Model
withNow msg =
    Task.perform msg Time.now |> Return.command


persistMaybeTodoCmd =
    Maybe.Extra.unwrap Cmd.none persistTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)


updateTodoWithAction action now todoId =
    let
        --        todoId = Todo.getId todo
        todoActionUpdater =
            case action of
                SetGroup group ->
                    Todo.setListType group

                ToggleDone ->
                    Todo.toggleDone

                Delete ->
                    Todo.markDeleted

        modifiedAtUpdater =
            Todo.setModifiedAt now

        todoUpdater =
            todoActionUpdater >> modifiedAtUpdater
    in
        updateTodoMaybe todoUpdater todoId


updateTodoMaybe : (Todo -> Todo) -> TodoId -> Model -> ( Model, Maybe Todo )
updateTodoMaybe updater todoId m =
    let
        todoList =
            m.todoList
                |> List.Extra.updateIf (Todo.hasId todoId) updater
    in
        ( Main.Model.setTodoList todoList m
        , List.Extra.find (Todo.hasId todoId) todoList
        )
