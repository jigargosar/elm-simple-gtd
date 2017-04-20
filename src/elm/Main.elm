port module Main exposing (..)

import Document
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
import Todo.Edit
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


port showNotification : TodoNotification -> Cmd msg


createTodoNotification todo =
    let
        id =
            Document.getId todo
    in
        { title = Todo.getText todo, tag = id, data = { id = id } }


port notificationClicked : (TodoNotificationEvent -> msg) -> Sub msg


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = update
        , view = appView
        , subscriptions = subscriptions
        }


init : Flags -> Return
init =
    Model.init >> Return.singleton


subscriptions m =
    Sub.batch
        [ Time.every Time.second (OnNowChanged)
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.keyUps OnKeyUp
        , notificationClicked OnNotificationClicked
        ]


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                NoOp ->
                    identity

                OnNotificationClicked { action, data } ->
                    let
                        _ =
                            Debug.log "action, data" ( action, data )

                        r =
                            case action of
                                "mark-done" ->
                                    Return.map (Model.updateTodoById [ Todo.SetDone True ] data.id)

                                _ ->
                                    identity
                    in
                        data.id |> SwitchToNotificationView >> andThenUpdate

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

                UpdateTodoForm etm field value ->
                    Return.map
                        (Todo.Edit.set field value etm
                            |> Model.setEditTodoModel
                        )

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

                EditTodoFormKeyUp { id } ke ->
                    case ke.key of
                        Key.Enter ->
                            andThenUpdateAll
                                (if ke.isShiftDown then
                                    [ SaveEditingEntity, CopyAndEditTodoById id ]
                                 else if ke.isMetaDown || ke.isControlDown then
                                    [ SaveEditingEntity ]
                                 else
                                    []
                                )

                        _ ->
                            identity

                TodoCheckBoxClicked todo ->
                    Return.map (Model.toggleSelection todo)

                SetView viewType ->
                    Return.map (Model.setMainViewType viewType)
                        >> andThenUpdate ClearSelection

                SwitchToNotificationView todoId ->
                    Return.withMaybe (Model.findTodoById todoId)
                        (NotificationView >> SetView >> andThenUpdate)

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

                        ToggleDeleted ->
                            Return.map (Model.toggleDeletedForEntity entity)

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


updateTodo : List Todo.UpdateAction -> Todo.Model -> ReturnF
updateTodo actions todo =
    Return.map (Model.updateTodo actions todo)


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


andThenUpdateAll =
    OnMsgList >> andThenUpdate


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
        >> sendNotifications


sendNotifications =
    Return.andThenMaybe
        (Model.findAndSnoozeOverDueTodo >>? Tuple.mapSecond showTodoNotificationCmd)


showTodoNotificationCmd =
    createTodoNotification >> showNotification


activateEditNewTodoMode text =
    Return.map (Model.activateNewTodoMode text)


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.stopRunningTodo)


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command
