module TodoListUpdate exposing (..)

import ActiveTask exposing (MaybeActiveTask)
import List.Extra as List
import Main.Model as Model
import Msg exposing (Msg)
import Main.Types exposing (Model, ModelF)
import Maybe.Extra
import Random.Pcg as Random
import Return exposing (Return, ReturnF)
import Task
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import PouchDB
import Tuple2
import TodoAction
import TodoMsg exposing (..)


todoInputId todo =
    "edit-todo-input-" ++ (Todo.getId todo)


onEditTodo =
    Msg.onEditTodo


updateMaybeMsg : Maybe TodoMsg -> Model -> ( Model, Cmd Msg )
updateMaybeMsg maybeMsg =
    Maybe.Extra.unwrap Return.singleton update maybeMsg


update : TodoMsg -> Model -> ( Model, Cmd Msg )
update msg =
    Return.singleton
        >> case msg of
            Start id ->
                startActiveTask id

            Stop ->
                stopTaskIfActive

            StopAndMarkDone ->
                markDoneIfActive
                    >> stopTaskIfActive

            OnRequiresNowAction action ->
                withNow (OnActionWithNow action)

            OnActionWithNow action now ->
                onWithNow action now


splitNewTodoAt todo now =
    Return.andThen
        (splitNewTodoFromAt todo now
            >> mapMaybeSecondToCmd
                (applyList
                    [ persistTodoCmd, onEditTodo.startEditing >> Msg.msgToCmd ]
                    >> Cmd.batch
                )
        )


onWithNow action now =
    case action of
        UpdateTodo action id ->
            updateAndPersistMaybeTodo (updateTodoAt action id now)

        CreateNewTodo text ->
            updateAndPersistMaybeTodo (addNewTodoAt text now)

        SplitNewTodoFrom todo ->
            splitNewTodoAt todo now


mapMaybeSecondToCmd maybeToCmd =
    Tuple2.mapSecond (Maybe.map maybeToCmd >> Maybe.withDefault Cmd.none)


startActiveTask : TodoId -> RF
startActiveTask id =
    Return.map (updateActiveTask (Model.getNow >> ActiveTask.start id))


type alias RF =
    Return Msg Model -> Return Msg Model


stopTaskIfActive : Return Msg Model -> Return Msg Model
stopTaskIfActive =
    Return.map (setActiveTask ActiveTask.init)


markDoneIfActive =
    Return.andThen
        (\m ->
            getActiveTask m
                ?|> ((.id) >> markDone >> (update # m))
                ?= Return.singleton m
        )


getActiveTask : Model -> MaybeActiveTask
getActiveTask =
    (.activeTask)


setActiveTask : MaybeActiveTask -> ModelF
setActiveTask activeTask model =
    { model | activeTask = activeTask }


updateActiveTask : (Model -> MaybeActiveTask) -> ModelF
updateActiveTask updater model =
    setActiveTask (updater model) model


addNewTodoAt text now m =
    if String.trim text |> String.isEmpty then
        ( m, Nothing )
    else
        Random.step (Todo.generator now text) (Model.getSeed m)
            |> Tuple.mapSecond (Model.setSeed # m)
            |> apply2 ( uncurry addTodo, Tuple.first >> Just )


splitNewTodoFromAt todo now m =
    Random.step (Todo.copyGenerator now todo) (Model.getSeed m)
        |> Tuple.mapSecond (Model.setSeed # m)
        |> apply2 ( uncurry addTodo, Tuple.first >> Just )


addTodo todo =
    updateTodoList (Model.getTodoList >> (::) todo)


setTodoList : TodoList -> ModelF
setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList : (Model -> TodoList) -> ModelF
updateTodoList updater model =
    setTodoList (updater model) model


updateAndPersistMaybeTodo updater =
    Return.andThen
        (updater >> Tuple2.mapSecond persistMaybeTodoCmd)


withNow : (Time -> TodoMsg) -> ReturnF Msg Model
withNow msg =
    Task.perform (msg >> Msg.OnTodoMsg) Time.now |> Return.command



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

                MarkDone ->
                    Todo.markDone

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
