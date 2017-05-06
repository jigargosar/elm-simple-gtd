port module Main exposing (..)

import CommonMsg
import Document
import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd)
import EditMode
import Ext.Debug
import Ext.Keyboard as Keyboard
import Ext.Return as Return
import Firebase
import Model.Internal as Model
import Model.RunningTodo as Model
import Project
import Ext.Random as Random
import Project
import Random.Pcg as Random exposing (Seed)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Encode as E
import Keyboard.Extra as Key
import Model as Model
import ReminderOverlay
import Routes
import Set
import Store
import String.Extra
import Todo
import Todo.Form
import Todo.ReminderForm
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
import View


port showNotification : TodoNotification -> Cmd msg


port closeNotification : String -> Cmd msg


createTodoNotification todo =
    let
        id =
            Document.getId todo
    in
        { title = Todo.getText todo, tag = id, data = { id = id } }


port notificationClicked : (TodoNotificationEvent -> msg) -> Sub msg


port syncWithRemotePouch : String -> Cmd msg


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = update
        , view = View.init
        , subscriptions = subscriptions
        }


init : Flags -> Return
init =
    Model.init >> Return.singleton


subscriptions m =
    Sub.batch
        [ Time.every (Time.second {- * 120 -}) (OnNowChanged)
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.keyUps OnKeyUp
        , notificationClicked OnNotificationClicked
        ]


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                OnCommonMsg msg ->
                    CommonMsg.update msg

                Login ->
                    Return.command (Firebase.login ())

                Logout ->
                    Return.command (Firebase.logout ())

                OnFirebaseUserChanged user ->
                    let
                        _ =
                            Debug.log "user" (user)
                    in
                        Return.map (Model.setUser user)

                SetFCMToken token ->
                    let
                        _ =
                            Debug.log "token" (token)
                    in
                        Return.map (Model.setFCMToken token)

                OnTestListItemFocus idx ->
                    Return.map
                        (\model ->
                            let
                                testModel =
                                    model.testModel
                            in
                                { model | testModel = { testModel | selectedIndex = idx } }
                        )

                SetMainViewFocusedDocumentId id ->
                    Return.map (\model -> { model | mainViewListFocusedDocumentId = id })

                OnTodoListKeyDown ( prevId, nextId ) { key } ->
                    case key of
                        Key.ArrowUp ->
                            Return.map
                                (\model ->
                                    { model | mainViewListFocusedDocumentId = prevId }
                                )
                                >> andThenUpdate (commonMsg.focus ".todo-list > [tabindex=0]")

                        Key.ArrowDown ->
                            Return.map
                                (\model ->
                                    { model | mainViewListFocusedDocumentId = nextId }
                                )
                                >> andThenUpdate (commonMsg.focus ".todo-list > [tabindex=0]")

                        _ ->
                            identity

                OnTestListKeyDown { key } ->
                    case key of
                        Key.ArrowUp ->
                            Return.map
                                (\model ->
                                    let
                                        testModel =
                                            model.testModel

                                        selectedIndex =
                                            testModel.selectedIndex
                                                - 1
                                                |> clamp 0 (testModel.list |> List.length >> (-) # 1)
                                    in
                                        { model | testModel = { testModel | selectedIndex = selectedIndex } }
                                )
                                >> andThenUpdate (commonMsg.focus ".test-list > [tabindex=0]")

                        Key.ArrowDown ->
                            Return.map
                                (\model ->
                                    let
                                        testModel =
                                            model.testModel

                                        selectedIndex =
                                            testModel.selectedIndex
                                                + 1
                                                |> clamp 0 (testModel.list |> List.length >> (-) # 1)
                                    in
                                        { model | testModel = { testModel | selectedIndex = selectedIndex } }
                                )
                                >> andThenUpdate (commonMsg.focus ".test-list > [tabindex=0]")

                        _ ->
                            identity

                ToggleDrawer ->
                    Return.map (Model.toggleForceNarrow)

                RemotePouchSync form ->
                    Return.map (\m -> { m | pouchDBRemoteSyncURI = form.uri })
                        >> Return.map Model.deactivateEditingMode
                        >> (syncWithRemotePouch form.uri |> command)

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
                        data.id |> ShowReminderOverlayForTodoId >> andThenUpdate

                ToggleShowDeletedEntity ->
                    Return.map ((\m -> { m | showDeleted = not m.showDeleted }))

                FocusPaperInput selector ->
                    focusPaperInputCmd selector

                AutoFocusPaperInput ->
                    autoFocusPaperInputCmd

                Start todo ->
                    Return.map (Model.startTodo todo)

                Stop ->
                    stopRunningTodo

                TodoAction action id ->
                    identity

                ReminderOverlayAction action ->
                    reminderOverlayAction action

                MarkRunningTodoDone ->
                    Return.withMaybe (Model.getMaybeRunningTodo)
                        (\todo -> updateTodo [ Todo.SetDone True ] todo >> stopRunningTodo)

                ToggleTodoDone todo ->
                    updateTodo [ Todo.ToggleDone ] todo

                SetTodoContext todoContext todo ->
                    updateTodo [ Todo.SetContext todoContext ] todo

                SetTodoProject project todo ->
                    updateTodo [ Todo.SetProject project ] todo

                StartAddingTodo ->
                    activateEditNewTodoMode ""
                        >> autoFocusPaperInputCmd

                NewProject ->
                    Return.map Model.createAndEditNewProject
                        >> autoFocusPaperInputCmd

                NewContext ->
                    Return.map Model.createAndEditNewContext
                        >> autoFocusPaperInputCmd

                NewTodoTextChanged text ->
                    activateEditNewTodoMode text

                DeactivateEditingMode ->
                    Return.map (Model.deactivateEditingMode)

                NewTodoKeyUp { text } { key } ->
                    case key of
                        Key.Enter ->
                            andThenUpdate (SaveCurrentForm)
                                >> andThenUpdate StartAddingTodo

                        Key.Escape ->
                            andThenUpdate DeactivateEditingMode

                        _ ->
                            identity

                StartEditingTodo todo ->
                    Return.map (Model.startEditingTodo todo)
                        >> autoFocusPaperInputCmd

                StartEditingReminder todo ->
                    Return.map (Model.startEditingReminder todo)
                        >> autoFocusPaperInputCmd

                UpdateTodoForm form action ->
                    Return.map
                        (Todo.Form.set action form
                            |> EditMode.TodoForm
                            >> Model.setEditMode
                        )

                UpdateRemoteSyncFormUri form uri ->
                    Return.map
                        ({ form | uri = uri }
                            |> EditMode.RemoteSync
                            >> Model.setEditMode
                        )

                UpdateReminderForm form action ->
                    Return.map
                        (Todo.ReminderForm.set action form
                            |> EditMode.TodoReminderForm
                            >> Model.setEditMode
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
                                ({- if ke.isShiftDown then
                                       [ SaveCurrentForm, CopyAndEditTodoById id ]
                                    else if ke.isMetaDown || ke.isControlDown then
                                       []
                                    else
                                 -}
                                 [ SaveCurrentForm, DeactivateEditingMode ]
                                )

                        _ ->
                            identity

                TodoCheckBoxClicked todo ->
                    Return.map (Model.toggleSelection todo)

                SetView viewType ->
                    Return.map (Model.setMainViewType viewType)
                        >> andThenUpdate ClearSelection

                ShowReminderOverlayForTodoId todoId ->
                    Return.map (Model.showReminderOverlayForTodoId todoId)

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

                SaveCurrentForm ->
                    Return.map (Model.saveCurrentForm)
                        >> andThenUpdate DeactivateEditingMode

                OnEntityAction entity action ->
                    case (action) of
                        StartEditing ->
                            Return.map (Model.startEditingEntity entity)
                                >> autoFocusPaperInputCmd

                        NameChanged newName ->
                            Return.map (Model.updateEditModeNameChanged newName entity)

                        Save ->
                            andThenUpdate SaveCurrentForm

                        ToggleDeleted ->
                            Return.map (Model.toggleDeletedForEntity entity)
                                >> andThenUpdate DeactivateEditingMode

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
        --        >> Return.map (Ext.Debug.tapLog .editMode "editmode")
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
    createTodoNotification >> showNotification >> (::) # [ startAlarm () ] >> Cmd.batch


activateEditNewTodoMode text =
    Return.map (Model.activateNewTodoMode text)


stopRunningTodo : ReturnF
stopRunningTodo =
    Return.map (Model.stopRunningTodo)


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command


reminderOverlayAction action =
    --                    Return.map (Model.updateReminderOverlay action)
    --                        >> Return.withMaybe (Model.getReminderOverlayTodoId)
    --                            (closeNotification >> Return.command)
    Return.andThen
        (\model ->
            model
                |> case model.reminderOverlay of
                    ReminderOverlay.Active activeView todoDetails ->
                        let
                            todoId =
                                todoDetails.id
                        in
                            case action of
                                ReminderOverlay.Dismiss ->
                                    Model.updateTodoById [ Todo.TurnReminderOff ] todoId
                                        >> Model.removeReminderOverlay
                                        >> Return.singleton
                                        >> Return.command (closeNotification todoId)

                                ReminderOverlay.ShowSnoozeOptions ->
                                    Model.setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                ReminderOverlay.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.map (Model.snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (closeNotification todoId)

                                ReminderOverlay.Close ->
                                    Model.removeReminderOverlay
                                        >> Return.singleton

                                _ ->
                                    Return.singleton

                    _ ->
                        Return.singleton
        )


(.=) =
    identity


foo =
    (\_ -> "f") .= "a"


command =
    Return.command
