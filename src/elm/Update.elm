port module Update exposing (..)

import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
import Ext.Return as Return
import Model.EditModel as Model
import Model.Internal as Model
import Model.RunningTodo as Model
import Model.TodoStore as Model
import Project exposing (Project, ProjectId, ProjectName)
import Ext.Random as Random
import ProjectStore
import Random.Pcg as Random exposing (Seed)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model
import Routes
import String.Extra
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
import Todo.Types as Todo exposing (Todo, TodoUpdateAction)
import Tuple2
import Html
import Msg exposing (..)
import RunningTodo
import Model.Types exposing (..)
import Types


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                NoOp ->
                    identity

                FocusPaperInput selector ->
                    focusPaperInputCmd selector

                Start todo ->
                    Return.map (Model.startTodo todo)

                Stop ->
                    stopRunningTodo

                MarkRunningTodoDone ->
                    Return.withMaybe (Model.getMaybeRunningTodo)
                        (\todo -> updateTodo [] (Todo.markDone todo) >> stopRunningTodo)

                ToggleTodoDone todo ->
                    updateTodo [ Todo.ToggleDone ] todo

                ToggleTodoDeleted todo ->
                    updateTodo [ Todo.ToggleDeleted ] todo

                SetTodoContext todoContext todo ->
                    updateTodo [ Todo.SetContext todoContext ] todo

                Create text ->
                    Return.mapModelWith Model.getNow
                        (\now -> Model.addNewTodo text now)

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
                    Return.map (Model.setEditModelToEditTodo todo)
                        >> autoFocusPaperInputCmd

                EditTodoTextChanged editTodoModel text ->
                    Return.map (Model.updateEditTodoText text editTodoModel)

                EditTodoProjectNameChanged editTodoModel projectName ->
                    Return.map (Model.updateEditTodoProjectName projectName editTodoModel)

                EditTodoKeyUp editTodoModel { key, isShiftDown } ->
                    case key of
                        Enter ->
                            onEditTodoEnterPressed editTodoModel isShiftDown

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
           )
        >> persist


persist =
    Return.andThen
        (\m ->
            Model.getProjectStore m
                |> PouchDB.persist
                |> Tuple.mapFirst (Model.setProjectStore # m)
        )
        >> Return.andThen
            (\m ->
                Model.getTodoStore m
                    |> PouchDB.persist
                    |> Tuple.mapFirst (Model.setTodoStore # m)
            )


updateTodoById actions todoId =
    Return.map (Model.updateTodoById actions todoId)


updateTodo : List TodoUpdateAction -> Todo -> ReturnF
updateTodo actions todo =
    Return.map (Model.updateTodo actions todo)


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
    Return.map (Model.deactivateEditingMode)


activateEditNewTodoMode text =
    Return.map (Model.activateNewTodoMode text)


onEditTodoEnterPressed : EditTodoModel -> Bool -> ReturnF
onEditTodoEnterPressed editTodoModel isShiftDown =
    Return.map (Model.insertProjectIfNotExist editTodoModel.projectName)
        >> updateTodoFromEditTodoModel editTodoModel
        >> whenBool isShiftDown (copyAndEditTodo editTodoModel.todo)
        >> deactivateEditingMode


copyAndEditTodo : Todo -> ReturnF
copyAndEditTodo todo =
    Return.andThenModelWith Model.getNow
        (\now ->
            Model.addCopyOfTodo todo now >> update (Msg.StartEditingTodo todo)
        )


updateTodoFromEditTodoModel : EditTodoModel -> ReturnF
updateTodoFromEditTodoModel { projectName, todoText, todoId } =
    Return.map
        (apply2Uncurry ( Model.findProjectByName projectName, identity )
            (\maybeProject ->
                Model.updateTodoById
                    [ Todo.SetText todoText
                    , Todo.SetProjectId (maybeProject ?|> Project.getId)
                    ]
                    todoId
            )
        )


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.stopRunningTodo)


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command
