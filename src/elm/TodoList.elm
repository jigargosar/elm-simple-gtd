module TodoList exposing (..)

import ActiveTask exposing (MaybeActiveTask)
import List.Extra as List
import Main.Model
import Main.Msg as Msg exposing (..)
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
import TodoListTypes exposing (..)
import PouchDB
import Tuple2
import TodoAction


toggleDone =
    UpdateTodo ToggleDone


markDone =
    UpdateTodo MarkDone


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


splitNewTodoFrom : Todo -> TodoMsg
splitNewTodoFrom =
    SplitNewTodoFrom


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone


todoInputId todo =
    "edit-todo-input-" ++ (Todo.getId todo)


update : (Msg -> Model -> Return Msg Model) -> TodoMsg -> Model -> ( Model, Cmd Msg )
update update2 msg =
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

            SplitNewTodoFrom todo ->
                withNow (SplitNewTodoFromAt todo)

            SplitNewTodoFromAt todo now ->
                Return.andThen
                    (splitNewTodoFromAt todo now
                        >> mapMaybeSecondToCmd
                            (applyList [ persistTodoCmd, onEditTodo.edit >> msgToCmd ] >> Cmd.batch)
                    )

            Start id ->
                startActiveTask id

            Stop ->
                stopTaskIfActive

            StopAndMarkDone ->
                markDoneIfActive (update update2)
                    >> stopTaskIfActive


mapMaybeSecondToCmd maybeToCmd =
    Tuple2.mapSecond (Maybe.map maybeToCmd >> Maybe.withDefault Cmd.none)


startActiveTask : TodoId -> RF
startActiveTask id =
    Return.map (updateActiveTask (Main.Model.getNow >> ActiveTask.start id))


type alias RF =
    Return Msg Model -> Return Msg Model


stopTaskIfActive : Return Msg Model -> Return Msg Model
stopTaskIfActive =
    Return.map (setActiveTask ActiveTask.init)


markDoneIfActive update =
    Return.andThen
        (\m ->
            getActiveTask m
                ?|> ((.id) >> toggleDone >> (update # m))
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
        Random.step (Todo.generator now text) (Main.Model.getSeed m)
            |> Tuple.mapSecond (Main.Model.setSeed # m)
            |> apply2 ( uncurry addTodo, Tuple.first >> Just )


splitNewTodoFromAt todo now m =
    Random.step (Todo.copyGenerator now todo) (Main.Model.getSeed m)
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
