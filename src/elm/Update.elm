port module Update exposing (..)

import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
import EditMode
import Ext.Keyboard as Keyboard
import Ext.Return as Return
import Model.EditMode as Model
import Model.Internal as Model
import Model.RunningTodo as Model
import Model.TodoStore as Model
import Project
import Ext.Random as Random
import Project
import Random.Pcg as Random exposing (Seed)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Encode as E
import Keyboard.Extra as Key
import Model
import Routes
import Set
import Store
import String.Extra
import Todo
import View exposing (appView)
import Navigation exposing (Location)
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Tuple2
import Html
import Msg exposing (..)
import RunningTodo
import Model.Types exposing (..)
import Types


port startSync : ( String, String ) -> Cmd msg


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                NoOp ->
                    identity

                OnMyPeerIdChanged id ->
                    Return.map ((\m -> { m | myPeerId = id }))

                OnRemotePeerIdChanged id ->
                    Return.map ((\m -> { m | remotePeerId = id }))

                StartSync ->
                    Return.effect_ (\m -> startSync ( m.myPeerId, m.remotePeerId ))

                ToggleShowDeletedEntity ->
                    Return.map ((\m -> { m | showDeleted = not m.showDeleted }))

                FocusPaperInput selector ->
                    focusPaperInputCmd selector

                Start todo ->
                    Return.map (Model.startTodo todo)

                Stop ->
                    stopRunningTodo

                MarkRunningTodoDone ->
                    Return.withMaybe (Model.getMaybeRunningTodo)
                        (\todo -> updateTodo [ Todo.SetDone True ] todo >> stopRunningTodo)

                ToggleTodoDone todo ->
                    updateTodo [ Todo.ToggleDone ] todo

                ToggleTodoDeleted todo ->
                    updateTodo [ Todo.ToggleDeleted ] todo

                SetTodoContext todoContext todo ->
                    updateTodo [ Todo.SetContext (todoContext) ] todo

                CreateTodo text ->
                    Return.mapModelWith Model.getNow
                        (\now -> Model.addNewTodo text now >> Tuple.second)

                StartAddingTodo ->
                    activateEditNewTodoMode ""
                        >> autoFocusPaperInputCmd

                NewTodoTextChanged text ->
                    activateEditNewTodoMode text

                DeactivateEditingMode ->
                    Return.map (Model.deactivateEditingMode)

                NewTodoKeyUp text { key } ->
                    case key of
                        Key.Enter ->
                            andThenUpdate (Msg.CreateTodo text)
                                >> andThenUpdate StartAddingTodo

                        Key.Escape ->
                            andThenUpdate DeactivateEditingMode

                        _ ->
                            identity

                StartEditingTodo todo ->
                    Return.map (Model.setEditModelToEditTodo todo)
                        >> autoFocusPaperInputCmd

                EditTodoTextChanged editTodoModel text ->
                    Return.map (Model.updateEditTodoText text editTodoModel)

                EditTodoProjectNameChanged editModel projectName ->
                    Return.map (Model.updateEditTodoProjectName projectName editModel)

                EditTodoContextNameChanged editModel contextName ->
                    Return.map (Model.updateEditTodoContextName contextName editModel)

                CopyAndEditTodoById todoId ->
                    Return.withMaybe (Model.findTodoById todoId)
                        (CopyAndEditTodo >> andThenUpdate)

                CopyAndEditTodo todo ->
                    Return.andThenApplyWith Model.getNow
                        (\now ->
                            Model.addCopyOfTodo todo now
                                >> Tuple.mapFirst Msg.StartEditingTodo
                                >> uncurry update
                        )

                EditTodoKeyUp { todoId } { key, isShiftDown } ->
                    case key of
                        Key.Enter ->
                            andThenUpdate SaveEditingEntity
                                >> andThenUpdate
                                    (if isShiftDown then
                                        CopyAndEditTodoById todoId
                                     else
                                        NoOp
                                    )

                        Key.Escape ->
                            andThenUpdate DeactivateEditingMode

                        _ ->
                            identity

                TodoCheckBoxClicked todo ->
                    Return.map (Model.toggleSelection todo)

                SetView viewType ->
                    Return.map (Model.setMainViewType viewType)
                        >> andThenUpdate ClearSelection

                ClearSelection ->
                    Return.map (Model.clearSelection)

                SelectionDoneClicked ->
                    Return.map (Model.clearSelection)

                SelectionEditClicked ->
                    Return.withMaybe (Model.getMaybeSelectedTodo)
                        (StartEditingTodo >> andThenUpdate)

                SelectionTrashClicked ->
                    Return.map (Model.clearSelection)

                OnNowChanged now ->
                    onUpdateNow now

                OnMsgList messages ->
                    onMsgList messages

                OnKeyboardMsg msg ->
                    Return.map (Model.update Model.keyboardState (Keyboard.update msg))

                SaveEditingEntity ->
                    Return.map (Model.saveEditModeEntity)
                        >> andThenUpdate DeactivateEditingMode

                OnEntityAction entity action ->
                    case (action) of
                        StartEditing ->
                            Return.map (Model.startEditingEntity entity)
                                >> autoFocusPaperInputCmd

                        NameChanged newName ->
                            Return.map (Model.updateEditModeNameChanged newName entity)

                        Save ->
                            andThenUpdate SaveEditingEntity

                        Delete ->
                            Return.map (Model.deleteEntity entity)

                OnKeyUp key ->
                    Return.with (Model.getEditMode)
                        (\editMode ->
                            case editMode of
                                EditMode.None ->
                                    case key of
                                        Key.CharQ ->
                                            andThenUpdate StartAddingTodo

                                        Key.CharC ->
                                            andThenUpdate ClearSelection

                                        Key.OpenBracket ->
                                            Return.command (Navigation.back 1)

                                        Key.CloseBracket ->
                                            Return.command (Navigation.forward 1)

                                        Key.CharG ->
                                            Return.map (Model.setEditMode EditMode.SwitchView)

                                        _ ->
                                            identity

                                EditMode.SwitchView ->
                                    (case key of
                                        Key.CharP ->
                                            andThenUpdate (SetView GroupByProjectView)

                                        Key.CharA ->
                                            andThenUpdate (SetView GroupByContextView)

                                        Key.CharB ->
                                            andThenUpdate (SetView BinView)

                                        Key.CharD ->
                                            andThenUpdate (SetView DoneView)

                                        _ ->
                                            identity
                                    )
                                        >> (case key of
                                                Key.CharG ->
                                                    Return.map (Model.setEditMode EditMode.SwitchToGroupedView)

                                                _ ->
                                                    andThenUpdate DeactivateEditingMode
                                           )

                                EditMode.SwitchToGroupedView ->
                                    (case key of
                                        Key.CharP ->
                                            andThenUpdate (SetView GroupByProjectView)

                                        Key.CharC ->
                                            andThenUpdate (SetView GroupByContextView)

                                        _ ->
                                            identity
                                    )
                                        >> andThenUpdate DeactivateEditingMode

                                _ ->
                                    (case key of
                                        Key.Escape ->
                                            andThenUpdate DeactivateEditingMode

                                        _ ->
                                            identity
                                    )
                        )
           )
        >> persistAll


persistAll =
    persist Model.projectStore
        >> persist Model.todoStore
        >> persist Model.contextStore


persist lens =
    Return.andThen
        (\m ->
            lens.get m
                |> Store.persist
                |> Tuple.mapFirst (lens.set # m)
        )


updateTodoById actions todoId =
    Return.map (Model.updateTodoById actions todoId)


updateTodo : List Todo.UpdateAction -> Todo.Model -> ReturnF
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


activateEditNewTodoMode text =
    Return.map (Model.activateNewTodoMode text)


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.stopRunningTodo)


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command
