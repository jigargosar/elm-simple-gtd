module TodoList exposing (..)

import List.Extra as List
import Main.Model exposing (Model)
import Main.Types exposing (ModelF)
import Maybe.Extra
import Random.Pcg as Random
import Return exposing (Return, ReturnF)
import Task
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Main.TodoListMsg exposing (..)
import PouchDB
import Tuple2
import TodoAction


toggleDone =
    UpdateTodo ToggleDone


toggleDelete =
    UpdateTodo ToggleDelete


setGroup : TodoGroup -> TodoId -> TodoMsg
setGroup =
    SetGroup >> UpdateTodo


setText : String -> TodoId -> TodoMsg
setText =
    SetText >> UpdateTodo


addNewTodo : String -> TodoMsg
addNewTodo =
    AddNewTodo


update : TodoMsg -> Model -> ( Model, Cmd TodoMsg )
update msg =
    Return.singleton
        >> case msg of
            UpdateTodo action id ->
                withNow (UpdateTodoAt action id)

            UpdateTodoAt action id now ->
                updateAndPersistMaybeTodo (updateTodoAt action id now)

            AddNewTodo text ->
                withNow (AddNewTodoAt text)

            AddNewTodoAt text now ->
                updateAndPersistMaybeTodo (addNewTodoAt text now)

            Start id ->
                identity


addNewTodoAt text now m =
    if String.trim text |> String.isEmpty then
        ( m, Nothing )
    else
        Random.step (Todo.generator now text) (Main.Model.getSeed m)
            |> Tuple.mapSecond (Main.Model.setSeed # m)
            |> apply2 ( uncurry addTodo, Tuple.first >> Just )


addTodo todo =
    updateTodoList (Main.Model.getTodoList >> (::) todo)


setTodoList : TodoList -> ModelF
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoList) -> ModelF
updateTodoList updater model =
    setTodoList (updater model) model


updateAndPersistMaybeTodo updater =
    Return.andThen
        (updater >> Tuple2.mapSecond persistMaybeTodoCmd)


withNow : (Time -> TodoMsg) -> ReturnF TodoMsg Model
withNow msg =
    Task.perform msg Time.now |> Return.command



--persistMaybeTodoCmd =
--    Maybe.Extra.unwrap Cmd.none persistTodoCmd


persistMaybeTodoCmd =
    Maybe.Extra.unwrap Cmd.none upsertTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)


upsertTodoCmd todo =
    PouchDB.pouchDBUpsert ( "todo-db", Todo.getId todo, (Todo.encode todo) )


updateTodoAt action todoId now =
    let
        todoActionUpdater =
            case action of
                SetGroup group ->
                    Todo.setListType group

                ToggleDone ->
                    Todo.toggleDone

                ToggleDelete ->
                    Todo.toggleDeleted

                SetText text ->
                    Todo.setText text

        modifiedAtUpdater =
            Todo.setModifiedAt now

        todoUpdater =
            todoActionUpdater >> modifiedAtUpdater
    in
        updateTodoMaybe todoUpdater todoId


updateTodoMaybe : (Todo -> Todo) -> TodoId -> Model -> ( Model, Maybe Todo )
updateTodoMaybe updater todoId m =
    let
        newTodoList =
            m.todoList
                |> List.updateIf (Todo.hasId todoId) updater
    in
        ( setTodoList newTodoList m
        , List.find (Todo.hasId todoId) newTodoList
        )
