port module Update exposing (..)

import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
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
import Model.Types exposing (..)
import Types


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            FocusPaperInput selector ->
                focusPaperInputCmd selector

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
                    >> autoFocusPaperInputCmd

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
                Return.map (Model.EditMode.setEditModeToEditTodo todo)
                    >> autoFocusPaperInputCmd

            EditTodoTextChanged etm text ->
                Return.map (Model.EditMode.updateEditTodoText text)

            EditTodoProjectNameChanged etm projectName ->
                Return.map (Model.EditMode.updateEditTodoProjectName projectName)

            EditTodoKeyUp todo { key, isShiftDown } ->
                case key of
                    Enter ->
                        saveAndDeactivateEditingTodo todo
                            >> whenBool isShiftDown
                                (Return.command (Msg.splitNewTodoFrom todo |> Msg.toCmd))

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            SetMainViewType viewType ->
                Return.map (Model.setMainViewType viewType)

            OnNowChanged now ->
                onUpdateNow now

            OnMsgList messages ->
                onMsgList messages

            UpdateTodoFields fields todo ->
                Return.andThen
                    (Model.TodoList.updateTodoWithFields fields (Todo.getId todo)
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


activateEditNewTodoMode text =
    Return.map (Model.EditMode.activateNewTodoMode text)


saveAndDeactivateEditingTodo : Todo -> ReturnF
saveAndDeactivateEditingTodo todo =
    Return.andThen
        (\m ->
            m
                |> Model.EditMode.getEditTodoModel
                ?|> (saveEditingTodoHelp todo # (Return.singleton m))
                ?= Return.singleton m
        )
        >> deactivateEditingMode


saveEditingTodoHelp : Todo -> EditTodoModel -> ReturnF
saveEditingTodoHelp todo editTodoModel =
    Return.andThen (getOrCreateAndPersistProject editTodoModel)
        >> Return.andThen (updateTodoFromEditTodoModel editTodoModel)


getOrCreateAndPersistProject : EditTodoModel -> Model -> ( ( Project, Model ), Cmd Msg )
getOrCreateAndPersistProject editTodoModel m =
    let
        { projectName } =
            editTodoModel

        maybeProject =
            Model.ProjectList.getProjectByName projectName m
    in
        case maybeProject of
            Nothing ->
                Model.ProjectList.createProject projectName (Model.getNow m) m
                    |> apply2 ( identity, Tuple.first >> upsertProjectCmd )

            Just project ->
                Return.singleton ( project, m )


updateTodoFromEditTodoModel editTodoModel ( project, m ) =
    let
        updateTodoMsg =
            Msg.UpdateTodoFields
                [ Types.TodoText editTodoModel.todoText
                , Types.TodoProject project
                ]
                editTodoModel.todo
    in
        update updateTodoMsg m


andThenMapSecond fun toCmd =
    Return.andThen (fun >> Tuple.mapSecond toCmd)


persistAndEditTodoCmd : ( Todo, Model ) -> Return
persistAndEditTodoCmd ( todo, model ) =
    persistTodoFromTuple ( todo, model )
        |> andThenUpdate (Msg.StartEditingTodo todo)


persistTodoFromTuple : ( Todo, Model ) -> Return
persistTodoFromTuple ( todo, model ) =
    ( model, upsertTodoCmd todo )


persistMaybeTodoFromTuple : ( Maybe Todo, Model ) -> Return
persistMaybeTodoFromTuple ( maybeTodo, model ) =
    case maybeTodo of
        Nothing ->
            model ! []

        Just todo ->
            model ! [ upsertTodoCmd todo ]


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
        >> uncurry (Maybe.unwrap identity (markDone >> andThenUpdate))


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



--persistTodoCmd todo =
--    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
--
--persistProjectCmd project =
--    PouchDB.pouchDBBulkDocsHelp "project-db" (Project.encodeSingleton project)


upsertTodoCmd todo =
    PouchDB.pouchDBUpsert ( "todo-db", Todo.getId todo, (Todo.encode todo) )


upsertProjectCmd project =
    PouchDB.pouchDBUpsert ( "project-db", Project.getId project, (Project.encode project) )


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
