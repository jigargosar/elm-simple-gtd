port module Main exposing (..)

import CommonMsg
import Document
import Dom
import DomPorts exposing (autoFocusInputCmd, focusInputCmd, focusSelectorIfNoFocusCmd)
import EditMode
import Entity
import Ext.Debug
import Ext.Keyboard as Keyboard exposing (Key)
import Ext.Return as Return
import Firebase
import LaunchBar
import LaunchBar.Form
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
import Model exposing (..)
import View


{-
   port showNotification : ( String, Bool, TodoNotification ) -> Cmd msg

   showNotificationCmd =
       curry3 showNotification
-}


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
        , Keyboard.keyUps OnGlobalKeyUp
        , notificationClicked OnNotificationClicked
        , Store.onChange OnPouchDBChange
        , Firebase.onChange OnFirebaseChange
        ]


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

                OnEntityListKeyDown entityList { key, isShiftDown } ->
                    case key of
                        Key.ArrowUp ->
                            Return.map (Model.focusPrevEntity entityList)
                                >> andThenUpdate setDomFocusToFocusedEntityCmd

                        Key.ArrowDown ->
                            Return.map (Model.focusNextEntity entityList)
                                >> andThenUpdate setDomFocusToFocusedEntityCmd

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

                FocusPaperInput selector ->
                    focusInputCmd selector

                AutoFocusPaperInput ->
                    autoFocusInputCmd

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
                        >> andThenUpdate setDomFocusToFocusedEntityCmd

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
                        >> Return.command (positionContextDropdownCmd todo)

                StartEditingProject todo ->
                    Return.map (Model.startEditingTodoProject todo)
                        >> Return.command (positionProjectDropdownCmd todo)

                UpdateTodoForm form action ->
                    Return.map
                        (Todo.Form.set action form
                            |> EditMode.EditTodo
                            >> Model.setEditMode
                        )

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

                OnMsgList messages ->
                    onMsgList messages

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

                        Entity.SetFocusedIn ->
                            Return.map (Model.setFocusInEntity entity)

                        Entity.SetFocused ->
                            Return.map (Model.setMaybeFocusedEntity (Just entity))

                        Entity.SetBlurred ->
                            Return.map (Model.setMaybeFocusedEntity Nothing)

                        Entity.ToggleSelected ->
                            Return.map (Model.toggleEntitySelection entity)

                OnLaunchBarActionWithNow action now ->
                    case action of
                        LaunchBar.OnEnter entity ->
                            andThenUpdate DeactivateEditingMode
                                >> case entity of
                                    LaunchBar.Project project ->
                                        map (Model.switchToProjectView project)

                                    LaunchBar.Context context ->
                                        map (Model.switchToContextView context)

                        LaunchBar.OnInputChanged form text ->
                            map (Model.updateLaunchBarInput now text form)

                        LaunchBar.Open ->
                            map (Model.activateLaunchBar now)
                                >> autoFocusInputCmd

                OnLaunchBarAction action ->
                    withNow (OnLaunchBarActionWithNow action)

                OnGlobalKeyUp key ->
                    onGlobalKeyUp key
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
            lens.get m
                |> Store.persist
                |> Tuple.mapFirst (lens.set # m)
        )


updateTodoAndMaybeAlsoSelected action todo =
    Return.andThen (Model.updateTodoAndMaybeAlsoSelected action (Document.getId todo))


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


andThenUpdateAll =
    OnMsgList >> andThenUpdate


setDomFocusToFocusedEntityCmd =
    (commonMsg.focus ".entity-list > [tabindex=0]")


onUpdateNow now =
    Return.map (Model.setNow now)
        >> sendNotifications


sendNotifications =
    Return.andThenMaybe
        (Model.findAndSnoozeOverDueTodo >>? showTodoNotificationCmd)


showTodoNotificationCmd ( ( todo, model ), cmd ) =
    let
        cmds =
            [ cmd, createTodoNotification todo |> showNotification, startAlarm () ]
    in
        model ! cmds


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
                            let
                                _ =
                                    Debug.log "slashpressed" ("slashpressed")
                            in
                                LaunchBar.Open |> OnLaunchBarAction |> andThenUpdate

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


positionContextDropdownCmd todo =
    DomPorts.positionDropdown ( "context-dropdown", "context-dropdown-" ++ Document.getId todo )


positionProjectDropdownCmd todo =
    DomPorts.positionDropdown ( "project-dropdown", "project-dropdown-" ++ Document.getId todo )


startSyncWithFirebase user =
    Return.maybeEffect (Model.getMaybeUserId >>? Firebase.startSyncCmd)
