port module Update exposing (..)

import Dom
import DomPorts exposing (focusFirstAutoFocusElement, focusPaperInput)
import Model.EditMode
import Model.ProjectList
import Model.RunningTodo
import Model.TodoList
import Project exposing (Project, ProjectId, ProjectName)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model as Model
import Routes
import View exposing (appView)
import Navigation exposing (Location)
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2
import Function exposing ((>>>))
import Html
import Msg exposing (..)
import RunningTodoDetails
import Types exposing (EditTodoModeModel, Model)


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            FocusPaperInput selector ->
                focusPaperInput selector

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
                        Return.command (Msg.saveNewTodo text |> Msg.toCmd)
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

            EditTodoProjectNameChanged projectName ->
                Return.map (Model.EditMode.updateEditTodoProjectName projectName)

            EditTodoBlur todo ->
                saveEditingTodoAndDeactivateEditing todo

            EditTodoKeyUp todo { key, isShiftDown } ->
                case key of
                    Enter ->
                        saveEditingTodoAndDeactivateEditing todo
                            >> whenBool isShiftDown
                                (Return.command (Msg.splitNewTodoFrom todo |> Msg.toCmd))

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            SetMainViewType viewState ->
                Return.map (Model.setMainViewType viewState)

            OnUpdateNow now ->
                onUpdateNow now

            OnMsgList messages ->
                onMsgList messages

            UpdateTodoFields fields todoId ->
                Return.andThen
                    (Model.TodoList.updateTodoWithFields fields todoId
                        >> updateTodoModifiedAt
                    )


updateTodoModifiedAt : ( Maybe Todo, Model ) -> Return
updateTodoModifiedAt ( maybeTodo, m ) =
    m
        |> Return.singleton
        >> case maybeTodo of
            Just todo ->
                let
                    id =
                        Todo.getId todo
                in
                    withNow (OnActionWithNow (Update UpdateModifiedAtUA id))

            Nothing ->
                identity


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


onUpdateNow now =
    Return.map (Model.setNow now)
        >> Return.andThen
            (\m ->
                let
                    shouldBeep =
                        Model.RunningTodo.shouldBeep m
                in
                    if shouldBeep then
                        ( Model.RunningTodo.updateLastBeepedTo now m, startAlarm () )
                    else
                        Return.singleton m
            )


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg


deactivateEditingMode =
    Return.map (Model.EditMode.deactivateEditingMode)


deactivateEditingModeFor : Todo -> ReturnF
deactivateEditingModeFor =
    Model.EditMode.deactivateEditingModeFor >> Return.map


activateEditNewTodoMode text =
    Return.map (Model.EditMode.activateEditNewTodoMode text)


saveEditingTodoAndDeactivateEditing : Todo -> ReturnF
saveEditingTodoAndDeactivateEditing todo =
    Return.andThen
        (\m ->
            m
                |> Model.EditMode.getEditTodoModeModel
                ?|> (saveEditingTodoHelp todo # (Return.singleton m))
                ?= Return.singleton m
        )
        >> deactivateEditingModeFor todo


saveEditingTodoHelp : Todo -> EditTodoModeModel -> ReturnF
saveEditingTodoHelp todo editTodoModel =
    Return.andThen (getOrCreateAndPersistProject editTodoModel)
        >> Return.andThen (updateTodoFromEditTodoModel editTodoModel)
        >> Return.command (Msg.SetText (Todo.getText todo) (Todo.getId todo) |> Msg.toCmd)


getOrCreateAndPersistProject : EditTodoModeModel -> Model -> ( ( Project, Model ), Cmd Msg )
getOrCreateAndPersistProject editTodoModel m =
    let
        { projectName } =
            editTodoModel

        maybeProject =
            Model.ProjectList.getProjectByName projectName m
    in
        case maybeProject of
            Nothing ->
                Model.ProjectList.createProject projectName m
                    |> apply2 ( identity, Tuple.first >> persistProject )

            Just project ->
                Return.singleton ( project, m )


updateTodoFromEditTodoModel editTodoModel ( project, m ) =
    let
        updateTodoMsg =
            Msg.UpdateTodoFields
                [ Types.TodoText editTodoModel.todoText
                , Types.TodoProject project
                ]
                editTodoModel.todoId
    in
        update updateTodoMsg m


persistProject project =
    Cmd.none


andThenMapSecond fun toCmd =
    Return.andThen (fun >> Tuple.mapSecond toCmd)


persistAndEditTodoCmd : ( Todo, Model ) -> Return
persistAndEditTodoCmd ( todo, model ) =
    persistTodoFromTuple ( todo, model )
        |> andThenUpdate (Msg.StartEditingTodo todo)


persistTodoFromTuple : ( Todo, Model ) -> Return
persistTodoFromTuple ( todo, model ) =
    ( model, persistTodoCmd todo )


persistMaybeTodoFromTuple : ( Maybe Todo, Model ) -> Return
persistMaybeTodoFromTuple ( maybeTodo, model ) =
    case maybeTodo of
        Nothing ->
            model ! []

        Just todo ->
            model ! [ persistTodoCmd todo ]


onWithNow : RequiresNowAction -> Time -> ReturnF
onWithNow action now =
    case action of
        Update action id ->
            Return.andThen (updateTodo action id now >> persistMaybeTodoFromTuple)

        CreateA text ->
            Return.andThen (addNewTodoAt text now >> persistTodoFromTuple)

        CopyAndEditA todo ->
            Return.andThen (copyNewTodo todo now >> persistAndEditTodoCmd)


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.RunningTodo.stopRunningTodo)


markRunningTodoDone : ReturnF
markRunningTodoDone =
    apply2 ( Tuple.first >> Model.RunningTodo.getRunningTodoId, identity )
        >> uncurry (Maybe.unwrap identity (markDone >> update >> Return.andThen))


addNewTodoAt : String -> Time -> Model -> ( Todo, Model )
addNewTodoAt text now =
    Model.generate (Todo.generator now text)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


copyNewTodo : Todo -> Time -> Model -> ( Todo, Model )
copyNewTodo todo now =
    Model.generate (Todo.copyGenerator now todo)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none upsertTodoCmd


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

                UpdateModifiedAtUA ->
                    identity

        modifiedAtUpdater =
            Todo.setModifiedAt now

        todoUpdater =
            todoActionUpdater >> modifiedAtUpdater
    in
        Model.TodoList.updateTodoMaybe todoUpdater todoId
