port module Update exposing (..)

import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
import EditModel.Types exposing (..)
import Ext.Return as Return
import Model.EditModel exposing (getMaybeEditTodoModel)
import Model.ProjectList exposing (getProjectByName)
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
import Todo as Todo
import TodoModel.Types exposing (..)
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

            SetTodoDone bool id ->
                updateTodoFieldsAndModifiedAt [ TodoDoneField bool ] id

            SetTodoContext todoContext id ->
                updateTodoFieldsAndModifiedAt [ TodoContextField todoContext ] id

            SetText text id ->
                updateTodoFieldsAndModifiedAt [ TodoTextField text ] id

            SetTodoDeleted bool id ->
                updateTodoFieldsAndModifiedAt [ TodoDeletedField bool ] id

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
                Return.map (Model.EditModel.setEditModelToEditTodo todo)
                    >> autoFocusPaperInputCmd

            EditTodoTextChanged etm text ->
                Return.map (Model.EditModel.updateEditTodoText text)

            EditTodoProjectNameChanged etm projectName ->
                Return.map (Model.EditModel.updateEditTodoProjectName projectName)

            EditTodoKeyUp todo { key, isShiftDown } ->
                case key of
                    Enter ->
                        saveAndDeactivateEditingTodo
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


updateMaybeTodoModifiedAt : ( Maybe TodoModel, Model ) -> Return
updateMaybeTodoModifiedAt ( maybeTodo, m ) =
    m
        |> Return.singleton
        >> case maybeTodo of
            Just todo ->
                let
                    id =
                        Todo.getId todo
                in
                    withNow (OnActionWithNow (UpdateTodoModifiedAt id))

            Nothing ->
                identity


updateTodoFieldsAndModifiedAt fields todoId =
    Return.map (Model.TodoList.updateTodoWithFields fields todoId)
        >> Return.andThen updateMaybeTodoModifiedAt


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
    Return.map (Model.EditModel.deactivateEditingMode)


activateEditNewTodoMode text =
    Return.map (Model.EditModel.activateNewTodoMode text)


saveAndDeactivateEditingTodo : ReturnF
saveAndDeactivateEditingTodo =
    Return.transformWithMaybe getMaybeEditTodoModel
        (\editTodoModel ->
            getOrCreateAndPersistProject editTodoModel
                >> updateTodoFromEditTodoModel editTodoModel
                >> deactivateEditingMode
        )



--returnAndMapTupleFirst : (x -> ReturnF) -> ReturnTuple x -> Return.Return Msg Model


getOrCreateAndPersistProject : EditTodoModel -> Return -> ReturnTuple Project
getOrCreateAndPersistProject editTodoModel =
    let
        { projectName } =
            editTodoModel
    in
        Return.transformWith (Model.ProjectList.getProjectByName projectName)
            (\maybeProject ->
                case maybeProject of
                    Nothing ->
                        createAndSaveProject projectName

                    Just project ->
                        Return.map ((,) project)
            )


createAndSaveProject projectName =
    Return.map (Model.ProjectList.addNewProject projectName)
        >> Return.effect_ (Tuple.first >> upsertProjectCmd)


updateTodoFromEditTodoModel : EditTodoModel -> ReturnTuple Project -> Return
updateTodoFromEditTodoModel editTodoModel =
    Return.transformTupleWith
        (\project ->
            updateTodoFieldsAndModifiedAt
                [ TodoTextField editTodoModel.todoText
                , TodoProjectIdField (project |> Project.getId >> Just)
                ]
                (Todo.getId editTodoModel.todo)
        )


onWithNow : RequiresNowAction -> Time -> ReturnF
onWithNow action now =
    case action of
        UpdateTodoModifiedAt id ->
            Return.andThen (Model.TodoList.updateTodoMaybe (Todo.setModifiedAt now) id >> persistMaybeTodoFromTuple)

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
        >> uncurry (Maybe.unwrap identity (SetTodoDone True >> andThenUpdate))


addNewTodoAt : String -> Time -> Model -> ( TodoModel, Model )
addNewTodoAt text now =
    Model.generate (Todo.todoGenerator now text)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


copyNewTodo : TodoModel -> Time -> Model -> ( TodoModel, Model )
copyNewTodo todo now =
    Model.generate (Todo.copyGenerator now todo)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command


persistAndEditTodoCmd : ( TodoModel, Model ) -> Return
persistAndEditTodoCmd ( todo, model ) =
    persistTodoFromTuple ( todo, model )
        |> andThenUpdate (Msg.StartEditingTodo todo)


persistTodoFromTuple : ( TodoModel, Model ) -> Return
persistTodoFromTuple ( todo, model ) =
    ( model, upsertTodoCmd todo )


persistMaybeTodoFromTuple : ( Maybe TodoModel, Model ) -> Return
persistMaybeTodoFromTuple ( maybeTodo, model ) =
    case maybeTodo of
        Nothing ->
            model ! []

        Just todo ->
            model ! [ upsertTodoCmd todo ]


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none upsertTodoCmd


upsertTodoCmd todo =
    PouchDB.pouchDBUpsert ( "todo-db", Todo.getId todo, (Todo.encodeTodo todo) )


upsertProjectCmd project =
    PouchDB.pouchDBUpsert ( "project-db", Project.getId project, (Project.encode project) )
