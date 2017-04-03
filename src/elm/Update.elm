port module Update exposing (..)

import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
import EditModel.Types exposing (..)
import Ext.Return as Return
import Model.EditModel exposing (getMaybeEditTodoModel)
import Model.ProjectList as Model exposing (findProjectByName)
import Model.RunningTodo as Model
import Model.TodoList
import Project exposing (Project, ProjectId, ProjectName)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
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
import RunningTodo
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
                Return.map (Model.startTodo id)

            Stop ->
                stopRunningTodo

            MarkRunningTodoDone ->
                Return.maybeTransformWith (Model.getRunningTodoId)
                    (updateTodo [ Todo.SetDone True ])
                    >> stopRunningTodo

            ToggleTodoDone id ->
                updateTodo [ Todo.ToggleDone ] id

            ToggleTodoDeleted id ->
                updateTodo [ Todo.ToggleDeleted ] id

            SetTodoContext todoContext id ->
                updateTodo [ Todo.SetContext todoContext ] id

            SetTodoText text id ->
                updateTodo [ Todo.SetText text ] id

            Create text ->
                Return.andThenWith Model.getNow
                    (\now -> addNewTodoAt text now >> persistTodoFromTuple)

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

            EditTodoTextChanged text ->
                Return.map (Model.EditModel.updateEditTodoText text)

            EditTodoProjectNameChanged projectName ->
                Return.map (Model.EditModel.updateEditTodoProjectName projectName)

            EditTodoKeyUp { key, isShiftDown } ->
                case key of
                    Enter ->
                        onEditTodoEnterPressed isShiftDown

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
    Return.andThenMaybe
        (Model.TodoList.updateAndGetTodo actions todoId ?>> persistTodoFromTuple)


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
                        Model.shouldBeep m
                in
                    if shouldBeep then
                        ( Model.setLastBeepedAt now m, startAlarm () )
                    else
                        Return.singleton m
            )


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg


deactivateEditingMode =
    Return.map (Model.EditModel.deactivateEditingMode)


activateEditNewTodoMode text =
    Return.map (Model.EditModel.activateNewTodoMode text)


onEditTodoEnterPressed : Bool -> ReturnF
onEditTodoEnterPressed isShiftDown =
    Return.maybeTransformWith getMaybeEditTodoModel
        (\editTodoModel ->
            findOrCreateProjectByName editTodoModel.projectName
                >> updateTodoFromEditTodoModel editTodoModel
                >> whenBool isShiftDown (copyAndEditTodo editTodoModel.todoId)
                >> deactivateEditingMode
        )


copyAndEditTodo todoId =
    Return.transformWith Model.getNow
        (\now ->
            Return.andThenMaybe
                (Model.TodoList.copyTodoById todoId now ?>> persistAndEditTodoCmd)
        )


updateTodoFromEditTodoModel : EditTodoModel -> ReturnTuple Project -> Return
updateTodoFromEditTodoModel editTodoModel =
    Return.transformModelTupleWith
        (\project ->
            updateTodo
                [ Todo.SetText editTodoModel.todoText
                , Todo.SetProject project
                ]
                editTodoModel.todoId
        )


findOrCreateProjectByName : ProjectName -> Return -> ReturnTuple Project
findOrCreateProjectByName projectName =
    Return.andThenWith (Model.findProjectByName projectName)
        (Maybe.unpack
            (\_ ->
                Model.addNewProject projectName
                    >> (\( project, model ) -> ( project, model ) ! [ upsertProjectCmd project ])
            )
            (\project -> (\model -> ( project, model ) ! []))
        )


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.stopRunningTodo)


addNewTodoAt : String -> Time -> Model -> ( Todo, Model )
addNewTodoAt text now =
    Model.generate (Todo.todoGenerator now text)
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


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none upsertTodoCmd


upsertTodoCmd todo =
    PouchDB.pouchDBUpsert ( "todo-db", Todo.getId todo, (Todo.encodeTodo todo) )


upsertProjectCmd project =
    PouchDB.pouchDBUpsert ( "project-db", Project.getId project, (Project.encode project) )
