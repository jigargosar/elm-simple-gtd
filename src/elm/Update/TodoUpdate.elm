module Update.TodoUpdate exposing (..)

import DomPorts exposing (focusFirstAutoFocusElement)
import Keyboard.Extra exposing (Key(..))
import Model.EditMode
import Model.RunningTodo
import Model.TodoList
import RunningTodoDetails exposing (RunningTodoDetails)
import List.Extra as List
import Model as Model
import Types exposing (Model, ModelF, Msg, Return, ReturnF)
import Maybe.Extra
import Random.Pcg as Random
import Return
import Task
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import PouchDB
import Tuple2
import Msg.TodoMsg exposing (..)


deactivateEditingMode =
    Return.map (Model.EditMode.deactivateEditingMode)


deactivateEditingModeFor : Todo -> ReturnF
deactivateEditingModeFor =
    Model.EditMode.deactivateEditingModeFor >> Return.map


activateEditNewTodoMode text =
    Return.map (Model.EditMode.activateEditNewTodoMode text)


setTodoTextAndDeactivateEditing todo =
    Return.command (Types.setText (Todo.getText todo) (Todo.getId todo) |> Types.toCmd)
        >> deactivateEditingModeFor todo


update : TodoMsg -> ReturnF
update msg =
    case msg of
        Start id ->
            Return.map (Model.RunningTodo.startTodo id)

        Stop ->
            stopRunningTodo

        MarkRunningTodoDone ->
            markRunningTodoDone
                >> stopRunningTodo

        OnActionWithNow action now ->
            onWithNow action now

        ToggleDone id ->
            withNow (OnActionWithNow (Update ToggleDoneUA id))

        MarkDone id ->
            withNow (OnActionWithNow (Update MarkDoneUA id))

        SetGroup group id ->
            withNow (OnActionWithNow (Update (SetGroupUA group) id))

        SetText text id ->
            withNow (OnActionWithNow (Update (SetTextUA text) id))

        ToggleDelete id ->
            withNow (OnActionWithNow (Update (ToggleDeleteUA) id))

        Create text ->
            withNow (OnActionWithNow (CreateA text))

        CopyAndEdit todo ->
            withNow (OnActionWithNow (CopyAndEditA todo))

        AddTodoClicked ->
            activateEditNewTodoMode ""
                >> focusFirstAutoFocusElement

        NewTodoTextChanged text ->
            activateEditNewTodoMode text

        NewTodoBlur ->
            deactivateEditingMode

        NewTodoKeyUp text { key } ->
            case key of
                Enter ->
                    Return.command (Types.saveNewTodo text |> Types.toCmd)
                        >> activateEditNewTodoMode ""

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity

        StartEditingTodo todo ->
            Return.map (Model.EditMode.activateEditTodoMode todo)
                >> focusFirstAutoFocusElement

        EditTodoTextChanged text ->
            Return.map (Model.EditMode.updateEditTodoText text)

        EditTodoBlur todo ->
            setTodoTextAndDeactivateEditing todo

        EditTodoKeyUp todo { key, isShiftDown } ->
            case key of
                Enter ->
                    setTodoTextAndDeactivateEditing todo
                        >> whenBool isShiftDown
                            (Return.command (Types.splitNewTodoFrom todo |> Types.toCmd))

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity


andThenMapSecond fun toCmd =
    Return.andThen (fun >> Tuple.mapSecond toCmd)


persistAndEditTodoCmd =
    applyList [ persistTodoCmd, Types.startEditingTodo >> Types.toCmd ]
        >> Cmd.batch


onWithNow action now =
    case action of
        Update action id ->
            updateAndPersistMaybeTodo (updateTodo action id now)

        CreateA text ->
            updateAndPersistMaybeTodo (addNewTodoAt text now)

        CopyAndEditA todo ->
            andThenMapSecond (copyNewTodo todo now) persistAndEditTodoCmd


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.RunningTodo.stopRunningTodo)


markRunningTodoDone : ReturnF
markRunningTodoDone =
    apply2 ( Tuple.first >> Model.RunningTodo.getRunningTodoId, identity )
        >> uncurry (Maybe.Extra.unwrap identity (markDone >> update))


addNewTodoAt text now m =
    if String.trim text |> String.isEmpty then
        ( m, Nothing )
    else
        Random.step (Todo.generator now text) (Model.getSeed m)
            |> Tuple.mapSecond (Model.setSeed # m)
            |> apply2 ( uncurry Model.TodoList.addTodo, Tuple.first >> Just )


copyNewTodo todo now m =
    Random.step (Todo.copyGenerator now todo) (Model.getSeed m)
        |> Tuple.mapSecond (Model.setSeed # m)
        |> apply2 ( uncurry Model.TodoList.addTodo, Tuple.first )


updateAndPersistMaybeTodo updater =
    Return.andThen
        (updater >> Tuple2.mapSecond persistMaybeTodoCmd)


withNow : (Time -> TodoMsg) -> ReturnF
withNow msg =
    Task.perform (msg >> Types.OnTodoMsg) Time.now |> Return.command


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
                SetGroupUA group ->
                    Todo.setListType group

                ToggleDoneUA ->
                    Todo.toggleDone

                MarkDoneUA ->
                    Todo.markDone

                ToggleDeleteUA ->
                    Todo.toggleDeleted

                SetTextUA text ->
                    Todo.setText text

        modifiedAtUpdater =
            Todo.setModifiedAt now

        todoUpdater =
            todoActionUpdater >> modifiedAtUpdater
    in
        Model.TodoList.updateTodoMaybe todoUpdater todoId
