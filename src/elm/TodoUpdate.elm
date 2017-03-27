module TodoUpdate exposing (..)

import RunningTodoDetails exposing (RunningTodoDetails)
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


updateMaybeMsg : Maybe TodoMsg -> Model -> ( Model, Cmd Msg )
updateMaybeMsg maybeMsg =
    Maybe.Extra.unwrap Return.singleton update maybeMsg


update : TodoMsg -> Model -> ( Model, Cmd Msg )
update msg =
    Return.singleton
        >> case msg of
            Start id ->
                startTodo id

            Stop ->
                stopRunningTodo

            StopAndMarkDone ->
                markRunningTodoDone
                    >> stopRunningTodo

            OnRequiresNowAction action ->
                withNow (OnActionWithNow action)

            OnActionWithNow action now ->
                onWithNow action now


andThenMapSecond fun toCmd =
    Return.andThen (fun >> Tuple.mapSecond toCmd)


persistAndEditTodoCmd =
    applyList [ persistTodoCmd, Msg.startEditingTodo >> Msg.toCmd ]
        >> Cmd.batch


onWithNow action now =
    case action of
        Update action id ->
            updateAndPersistMaybeTodo (updateTodo action id now)

        Create text ->
            updateAndPersistMaybeTodo (addNewTodoAt text now)

        CopyAndEdit todo ->
            andThenMapSecond (copyNewTodo todo now) persistAndEditTodoCmd


startTodo : TodoId -> RF
startTodo id =
    Return.map (updateRunningTodoDetails (Model.getNow >> RunningTodoDetails.start id))


type alias RF =
    Return Msg Model -> Return Msg Model


stopRunningTodo : Return Msg Model -> Return Msg Model
stopRunningTodo =
    Return.map (setRunningTodoDetails RunningTodoDetails.init)


markRunningTodoDone =
    apply2 ( Tuple.first >> Model.getRunningTodoId, identity )
        >> uncurry markMaybeTodoIdDone


markMaybeTodoIdDone =
    Maybe.Extra.unwrap identity (markDone >> update >> Return.andThen)


setRunningTodoDetails : Maybe RunningTodoDetails -> ModelF
setRunningTodoDetails runningTodoDetails model =
    { model | runningTodoDetails = runningTodoDetails }


updateRunningTodoDetails : (Model -> Maybe RunningTodoDetails) -> ModelF
updateRunningTodoDetails updater model =
    setRunningTodoDetails (updater model) model


addNewTodoAt text now m =
    if String.trim text |> String.isEmpty then
        ( m, Nothing )
    else
        Random.step (Todo.generator now text) (Model.getSeed m)
            |> Tuple.mapSecond (Model.setSeed # m)
            |> apply2 ( uncurry addTodo, Tuple.first >> Just )


copyNewTodo todo now m =
    Random.step (Todo.copyGenerator now todo) (Model.getSeed m)
        |> Tuple.mapSecond (Model.setSeed # m)
        |> apply2 ( uncurry addTodo, Tuple.first )


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


updateTodo action todoId now =
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
