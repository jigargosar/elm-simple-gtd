port module Main exposing (..)

import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusInputCmd, focusSelectorIfNoFocusCmd)
import EditMode
import Entity
import Ext.Debug
import Ext.Keyboard as Keyboard exposing (Key)
import Ext.Record as Record exposing (set)
import Ext.Return as Return
import Firebase
import Keyboard.Combo
import LaunchBar
import Ext.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Model as Model
import Notification exposing (Response)
import ReminderOverlay
import Routes
import Store
import Todo
import Todo.Form
import Todo.GroupForm
import Todo.ReminderForm
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model exposing (..)
import Todo.Main
import View


port closeNotification : String -> Cmd msg


createTodoNotification todo =
    let
        id =
            Document.getId todo
    in
        { title = Todo.getText todo, tag = id, data = { id = id } }


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


type alias Return =
    Return.Return Msg Model


type alias ReturnTuple a =
    Return.Return Msg ( a, Model )


type alias ReturnF =
    Return -> Return


init : Flags -> Return
init =
    Model.init >> Return.singleton


subscriptions m =
    Sub.batch
        [ Time.every (Time.second * 1) OnNowChanged
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.ups OnGlobalKeyUp
        , Store.onChange OnPouchDBChange
        , Firebase.onChange OnFirebaseChange
        , Keyboard.Combo.subscriptions m.keyComboModel
        , Todo.Main.subscriptions m
        ]


over =
    Record.over >>> map


set =
    Record.set >>> map


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                OnCommonMsg msg ->
                    CommonMsg.update msg

                OnPouchDBChange dbName encodedDoc ->
                    Return.map (Model.upsertEncodedDocOnPouchDBChange dbName encodedDoc)

                OnFirebaseChange dbName encodedDoc ->
                    Return.effect_ (Model.upsertEncodedDocOnFirebaseChange dbName encodedDoc)

                SignIn ->
                    Return.command (Firebase.signIn ())

                SignOut ->
                    Return.command (Firebase.signOut ())

                OnUserChanged user ->
                    Return.map (Model.setUser user)
                        >> Return.maybeEffect firebaseUpdateClientCmd
                        >> Return.maybeEffect firebaseSetupOnDisconnectCmd
                        >> startSyncWithFirebase user

                OnFCMTokenChanged token ->
                    let
                        _ =
                            Debug.log "fcm: token" (token)
                    in
                        Return.map (Model.setFCMToken token)
                            >> Return.maybeEffect firebaseUpdateClientCmd

                OnFirebaseConnectionChanged connected ->
                    Return.map (Model.updateFirebaseConnection connected)
                        >> Return.maybeEffect firebaseUpdateClientCmd

                OnSetDomFocusToFocusInEntity ->
                    andThenUpdate setDomFocusToFocusInEntityCmd

                OnEntityListKeyDown entityList { key, isShiftDown } ->
                    case key of
                        Key.ArrowUp ->
                            Return.map (Model.moveFocusBy -1 entityList)
                                >> andThenUpdate OnSetDomFocusToFocusInEntity

                        Key.ArrowDown ->
                            Return.map (Model.moveFocusBy 1 entityList)
                                >> andThenUpdate OnSetDomFocusToFocusInEntity

                        _ ->
                            identity

                ToggleDrawer ->
                    Return.map (Model.toggleLayoutForceNarrow)

                OnLayoutNarrowChanged bool ->
                    Return.map (Model.setLayoutNarrow bool)

                RemotePouchSync form ->
                    andThenUpdate SaveCurrentForm
                        >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

                OnNotificationClicked { action, data } ->
                    let
                        todoId =
                            data.id
                    in
                        if action == "mark-done" then
                            Return.andThen (Model.updateTodo Todo.MarkDone todoId)
                                >> command (closeNotification todoId)
                        else
                            todoId |> ShowReminderOverlayForTodoId >> andThenUpdate

                ToggleShowDeletedEntity ->
                    Return.map ((\m -> { m | showDeleted = not m.showDeleted }))

                TodoAction action id ->
                    identity

                ReminderOverlayAction action ->
                    reminderOverlayAction action

                ToggleTodoDone todoId ->
                    Return.andThen (Model.updateTodo Todo.ToggleDone todoId)

                SetTodoContext todoContext todo ->
                    updateTodoAndMaybeAlsoSelected (Todo.SetContext todoContext) todo
                        >> andThenUpdate DeactivateEditingMode

                SetTodoProject project todo ->
                    updateTodoAndMaybeAlsoSelected (Todo.SetProject project) todo
                        >> andThenUpdate DeactivateEditingMode

                NewTodoTextChanged form text ->
                    Return.map (Model.updateNewTodoText form text)

                DeactivateEditingMode ->
                    Return.map (Model.deactivateEditingMode)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                NewTodoKeyUp { key } ->
                    case key of
                        Key.Enter ->
                            andThenUpdate (SaveCurrentForm)

                        _ ->
                            identity

                StartEditingReminder todo ->
                    Return.map (Model.startEditingReminder todo)
                        >> autoFocusInputCmd

                StartEditingContext todo ->
                    Return.map (Model.startEditingTodoContext todo)
                        >> Return.command (positionContextMenuCmd todo)

                StartEditingProject todo ->
                    Return.map (Model.startEditingTodoProject todo)
                        >> Return.command (positionProjectMenuCmd todo)

                UpdateTodoForm form action ->
                    Return.map
                        (Todo.Form.set action form
                            |> EditMode.EditTodo
                            >> Model.setEditMode
                        )

                OnEditTodoProjectMenuStateChanged form menuState ->
                    Return.map
                        (Todo.GroupForm.setMenuState menuState form
                            |> EditMode.EditTodoProject
                            >> Model.setEditMode
                        )
                        >> autoFocusInputCmd

                OnEditTodoContextMenuStateChanged form menuState ->
                    Return.map
                        (Todo.GroupForm.setMenuState menuState form
                            |> EditMode.EditTodoContext
                            >> Model.setEditMode
                        )
                        >> autoFocusInputCmd

                UpdateRemoteSyncFormUri form uri ->
                    Return.map
                        ({ form | uri = uri }
                            |> EditMode.EditSyncSettings
                            >> Model.setEditMode
                        )

                UpdateReminderForm form action ->
                    Return.map
                        (Todo.ReminderForm.set action form
                            |> EditMode.EditTodoReminder
                            >> Model.setEditMode
                        )

                SwitchView viewType ->
                    Return.map (Model.switchToView viewType)

                SetGroupByView viewType ->
                    Return.map (Model.setEntityListViewType viewType)

                ShowReminderOverlayForTodoId todoId ->
                    Return.map (Model.showReminderOverlayForTodoId todoId)

                OnNowChanged now ->
                    onUpdateNow now

                OnKeyboardMsg msg ->
                    Return.map (Model.updateKeyboardState (Keyboard.update msg))
                        >> focusSelectorIfNoFocusCmd ".entity-list > [tabindex=0]"

                SaveCurrentForm ->
                    Return.andThen Model.saveCurrentForm
                        >> andThenUpdate DeactivateEditingMode

                NewTodo ->
                    Return.map (Model.activateNewTodoModeWithFocusInEntityAsReference)
                        >> autoFocusInputCmd

                NewTodoForInbox ->
                    Return.map (Model.activateNewTodoModeWithInboxAsReference)
                        >> autoFocusInputCmd

                NewProject ->
                    Return.map Model.createAndEditNewProject
                        >> autoFocusInputCmd

                NewContext ->
                    Return.map Model.createAndEditNewContext
                        >> autoFocusInputCmd

                OnEntityAction entity action ->
                    case (action) of
                        Entity.StartEditing ->
                            Return.map (Model.startEditingEntity entity)
                                >> autoFocusInputCmd

                        Entity.NameChanged newName ->
                            Return.map (Model.updateEditModeNameChanged newName entity)

                        Entity.Save ->
                            andThenUpdate SaveCurrentForm

                        Entity.ToggleDeleted ->
                            Return.andThen (Model.toggleDeleteEntity entity)
                                >> andThenUpdate DeactivateEditingMode

                        Entity.OnFocusIn ->
                            Return.map (Model.setFocusInEntity entity)

                        Entity.ToggleSelected ->
                            Return.map (Model.toggleEntitySelection entity)

                        Entity.Goto ->
                            Return.map (Model.switchToEntityListViewFromEntity entity)

                OnLaunchBarMsgWithNow msg now ->
                    case msg of
                        LaunchBar.OnEnter entity ->
                            andThenUpdate DeactivateEditingMode
                                >> case entity of
                                    LaunchBar.Project project ->
                                        map (Model.switchToProjectView project)

                                    LaunchBar.Projects ->
                                        map (Model.setEntityListViewType Entity.ProjectsView)

                                    LaunchBar.Context context ->
                                        map (Model.switchToContextView context)

                                    LaunchBar.Contexts ->
                                        map (Model.setEntityListViewType Entity.ContextsView)

                        LaunchBar.OnInputChanged form text ->
                            map (Model.updateLaunchBarInput now text form)

                        LaunchBar.Open ->
                            map (Model.activateLaunchBar now) >> autoFocusInputCmd

                OnLaunchBarMsg msg ->
                    withNow (OnLaunchBarMsgWithNow msg)

                OnCloseNotification tag ->
                    command (closeNotification tag)

                OnGlobalKeyUp key ->
                    onGlobalKeyUp key

                OnKeyCombo comboMsg ->
                    Return.andThen (Model.updateCombo comboMsg)

                OnTodoMsg todoMsg ->
                    withNow (OnTodoMsgWithTime todoMsg)

                OnTodoMsgWithTime todoMsg now ->
                    Todo.Main.update andThenUpdate now todoMsg
           )
        >> persistAll


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


map =
    Return.map


modelTapLog =
    Ext.Debug.tapLog >>> Return.map


persistAll =
    persist Model.projectStore
        >> persist Model.todoStore
        >> persist Model.contextStore


persist lens =
    Return.andThen
        (\m ->
            Record.get lens m
                |> Store.persist
                |> Tuple.mapFirst (Record.set lens # m)
        )


updateTodoAndMaybeAlsoSelected action todo =
    Return.andThen (Model.updateTodoAndMaybeAlsoSelected action (Document.getId todo))


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list > [tabindex=0]")


onUpdateNow now =
    Return.map (Model.setNow now)
        >> sendNotifications
        >> andThenUpdate Model.onUpdateTodoTimeTracker


sendNotifications =
    Return.andThenMaybe
        (Model.findAndSnoozeOverDueTodo >>? showTodoNotificationCmd)


showTodoNotificationCmd ( ( todo, model ), cmd ) =
    let
        cmds =
            [ cmd, createTodoNotification todo |> Todo.Main.showTodoReminderNotification, startAlarm () ]
    in
        model ! cmds


triggerAlarmCmd bool =
    if bool then
        startAlarm ()
    else
        Cmd.none


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


reminderOverlayAction action =
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
                                    Model.updateTodo (Todo.TurnReminderOff) todoId
                                        >> Tuple.mapFirst Model.removeReminderOverlay
                                        >> Return.command (closeNotification todoId)

                                ReminderOverlay.ShowSnoozeOptions ->
                                    Model.setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                ReminderOverlay.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.andThen (Model.snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (closeNotification todoId)

                                ReminderOverlay.Close ->
                                    Model.removeReminderOverlay
                                        >> Return.singleton

                                ReminderOverlay.MarkDone ->
                                    Model.updateTodo Todo.MarkDone todoId
                                        >> Tuple.mapFirst Model.removeReminderOverlay
                                        >> Return.command (closeNotification todoId)

                    _ ->
                        Return.singleton
        )


command =
    Return.command


onGlobalKeyUp : Key -> ReturnF
onGlobalKeyUp key =
    Return.with (Model.getEditMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, EditMode.None ) ->
                    case key of
                        Key.Escape ->
                            Return.map (Model.clearSelection)

                        Key.CharQ ->
                            andThenUpdate NewTodo

                        Key.CharI ->
                            andThenUpdate NewTodoForInbox

                        Key.Slash ->
                            LaunchBar.Open |> OnLaunchBarMsg |> andThenUpdate

                        Key.CharR ->
                            andThenUpdate Model.onGotoRunningTodo

                        _ ->
                            identity

                ( Key.Escape, _ ) ->
                    andThenUpdate DeactivateEditingMode

                _ ->
                    identity
        )


firebaseUpdateClientCmd model =
    Model.getMaybeUserId model
        ?|> apply2
                ( Firebase.updateTokenCmd model.deviceId model.fcmToken
                , Firebase.updateClientCmd model.firebaseClient
                )
        >> Tuple2.toList
        >> Cmd.batch


firebaseSetupOnDisconnectCmd model =
    Model.getMaybeUserId model
        ?|> Firebase.setupOnDisconnectCmd model.firebaseClient


positionContextMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-context-buton-" ++ Document.getId todo)


positionProjectMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-project-buton-" ++ Document.getId todo)


startSyncWithFirebase user =
    Return.maybeEffect (Model.getMaybeUserId >>? Firebase.startSyncCmd)
