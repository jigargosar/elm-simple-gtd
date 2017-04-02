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
import Todo.Types as Todo exposing (Todo)
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

            SetTodoDone bool id ->
                updateTodo [ Todo.SetDone bool ] id

            ToggleTodoDone id ->
                updateTodo [ Todo.ToggleDone ] id

            ToggleTodoDeleted id ->
                updateTodo [ Todo.ToggleDeleted ] id

            SetTodoContext todoContext id ->
                updateTodo [ Todo.SetContext todoContext ] id

            SetTodoText text id ->
                updateTodo [ Todo.SetText text ] id

            SetTodoDeleted bool id ->
                updateTodo [ Todo.SetDeleted bool ] id

            Create text ->
                Return.transformWith Model.getNow
                    (\now -> Return.andThen (addNewTodoAt text now >> persistTodoFromTuple))

            CopyAndEdit todo ->
                Return.transformWith Model.getNow
                    (\now -> Return.andThen (copyNewTodo todo now >> persistAndEditTodoCmd))

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


updateTodo actions todoId =
    Return.map (Model.TodoList.updateAndGetTodo actions todoId)
        >> Return.andThen persistMaybeTodoFromTuple


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
    Return.maybeTransformWith getMaybeEditTodoModel
        (\editTodoModel ->
            findOrCreateProjectByName editTodoModel.projectName
                >> updateTodoFromEditTodoModel editTodoModel
                >> deactivateEditingMode
        )


findOrCreateProjectByName : ProjectName -> Return -> ReturnTuple Project
findOrCreateProjectByName projectName =
    Return.transformWith (Model.ProjectList.getProjectByName projectName)
        (\maybeProject ->
            case maybeProject of
                Nothing ->
                    createAndPersistProject projectName

                Just project ->
                    Return.map ((,) project)
        )


createAndPersistProject projectName =
    Return.map (Model.ProjectList.addNewProject projectName)
        >> Return.effect_ (Tuple.first >> upsertProjectCmd)


updateTodoFromEditTodoModel : EditTodoModel -> ReturnTuple Project -> Return
updateTodoFromEditTodoModel editTodoModel =
    Return.transformModelTupleWith
        (\project ->
            updateTodo
                [ Todo.SetText editTodoModel.todoText
                , Todo.SetProject project
                ]
                (Todo.getId editTodoModel.todo)
        )


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.RunningTodo.stopRunningTodo)


markRunningTodoDone : ReturnF
markRunningTodoDone =
    Return.maybeTransformWith (Model.RunningTodo.getRunningTodoId)
        (SetTodoDone True >> andThenUpdate)


addNewTodoAt : String -> Time -> Model -> ( Todo, Model )
addNewTodoAt text now =
    Model.generate (Todo.todoGenerator now text)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


copyNewTodo : Todo -> Time -> Model -> ( Todo, Model )
copyNewTodo todo now =
    Model.generate (Todo.copyGenerator now todo)
        >> apply2 ( Tuple.first, uncurry Model.TodoList.addTodo )


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command


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


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none upsertTodoCmd


upsertTodoCmd todo =
    PouchDB.pouchDBUpsert ( "todo-db", Todo.getId todo, (Todo.encodeTodo todo) )


upsertProjectCmd project =
    PouchDB.pouchDBUpsert ( "project-db", Project.getId project, (Project.encode project) )
