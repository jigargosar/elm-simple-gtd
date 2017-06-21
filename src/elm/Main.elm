port module Main exposing (..)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusInputCmd, focusSelectorIfNoFocusCmd)
import ExclusiveMode
import Entity
import Ext.Debug
import Ext.Keyboard as Keyboard exposing (Key)
import Ext.Record as Record exposing (set)
import Ext.Return as Return
import Firebase
import Http
import Keyboard.Combo
import LaunchBar
import Ext.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Maybe.Extra as Maybe
import Model as Model
import Notification exposing (Response)
import ReminderOverlay
import Routes
import Store
import Todo
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Todo.ReminderForm
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Model exposing (..)
import Task.Main
import View
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


port syncWithRemotePouch : String -> Cmd msg


port persistLocalPref : D.Value -> Cmd msg


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = Model.init
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


subscriptions m =
    Sub.batch
        [ Time.every (Time.second * 1) OnNowChanged
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.ups OnGlobalKeyUp
        , Store.onChange OnPouchDBChange
        , Firebase.onChange OnFirebaseChange
        , Keyboard.Combo.subscriptions m.keyComboModel
        , Task.Main.subscriptions m
        ]


over =
    Record.over >>> map


set =
    Record.set >>> map


welcomeEntitiesURL =
    "https://firebasestorage.googleapis.com/v0/b/simple-gtd-prod.appspot.com/o/public%2Fwelcome-entities.json?alt=media"


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                NOOP ->
                    identity

                OnCommonMsg msg ->
                    CommonMsg.update msg

                OnPouchDBChange dbName encodedDoc ->
                    Return.andThenMaybe
                        (Model.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                            >>? Tuple.mapFirst OnEntityUpsert
                            >>? uncurry update
                        )

                OnEntityUpsert entity ->
                    case entity of
                        Entity.Task model ->
                            Todo.Msg.Upsert model |> andThenTodoMsg

                        _ ->
                            identity

                OnFirebaseChange dbName encodedDoc ->
                    Return.effect_ (Model.upsertEncodedDocOnFirebaseChange dbName encodedDoc)

                OnSignIn ->
                    Return.command (Firebase.signIn ())
                        >> andThenUpdate OnDeactivateEditingMode

                SignOut ->
                    Return.command (Firebase.signOut ())

                OnUserChanged user ->
                    Return.map (Model.setUser user)
                        >> Return.maybeEffect firebaseUpdateClientCmd
                        >> Return.maybeEffect firebaseSetupOnDisconnectCmd
                        >> startSyncWithFirebase user

                OnFCMTokenChanged token ->
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
                    andThenUpdate OnSaveCurrentForm
                        >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

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
                        >> andThenUpdate OnDeactivateEditingMode

                SetTodoProject project todo ->
                    updateTodoAndMaybeAlsoSelected (Todo.SetProject project) todo
                        >> andThenUpdate OnDeactivateEditingMode

                NewTodoTextChanged form text ->
                    Return.map (Model.updateNewTodoText form text)

                OnDeactivateEditingMode ->
                    Return.map (Model.deactivateEditingMode)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                OnCreateDefaultEntitiesWithResult result ->
                    let
                        _ =
                            Debug.log "result" (result)
                    in
                        identity

                OnCreateDefaultEntities ->
                    let
                        cmd =
                            Http.get welcomeEntitiesURL D.value
                                |> Http.send OnCreateDefaultEntitiesWithResult
                    in
                        map
                            (Model.createProject "Explore SimpleGTD.com"
                                >> Model.createProject "GTD: Learn"
                                >> Model.createContext "1 Now"
                                >> Model.createContext "2 Next Actions"
                                >> Model.createContext "3 Waiting For"
                                >> Model.createContext "zz SomeDay/Maybe"
                                >> Model.createTodo "Click `+` or press `q` for quick add"
                                >> Model.createTodo "press `i` to create and add to Inbox"
                                >> Model.createTodo "press `e` to edit text"
                                >> Model.createTodo "press `c` to set context"
                                >> Model.createTodo "press `p` to set project"
                                >> Model.createTodo "press `r` to set schedule/reminder"
                                >> Model.createTodo "use `ArrowUp` and `ArrowDown` keys to focus item"
                            )
                            >> andThenUpdate OnDeactivateEditingMode
                            >> command cmd

                StartEditingReminder todo ->
                    Return.map (Model.startEditingReminder todo)
                        >> Return.command (positionScheduleMenuCmd todo)

                StartEditingContext todo ->
                    Return.map (Model.startEditingTodoContext todo)
                        >> Return.command (positionContextMenuCmd todo)

                StartEditingProject todo ->
                    Return.map (Model.startEditingTodoProject todo)
                        >> Return.command (positionProjectMenuCmd todo)

                UpdateTodoForm form action ->
                    Return.map
                        (Todo.Form.set action form
                            |> ExclusiveMode.EditTask
                            >> Model.setEditMode
                        )

                OnEditTodoProjectMenuStateChanged form menuState ->
                    Return.map
                        (Todo.GroupForm.setMenuState menuState form
                            |> ExclusiveMode.EditTodoProject
                            >> Model.setEditMode
                        )
                        >> autoFocusInputCmd

                OnEditTodoContextMenuStateChanged form menuState ->
                    Return.map
                        (Todo.GroupForm.setMenuState menuState form
                            |> ExclusiveMode.EditTodoContext
                            >> Model.setEditMode
                        )
                        >> autoFocusInputCmd

                UpdateRemoteSyncFormUri form uri ->
                    Return.map
                        ({ form | uri = uri }
                            |> ExclusiveMode.EditSyncSettings
                            >> Model.setEditMode
                        )

                OnSetViewType viewType ->
                    Return.map (Model.switchToView viewType)

                OnSetEntityListView viewType ->
                    Return.map (Model.setEntityListViewType viewType)

                OnNowChanged now ->
                    onUpdateNow now

                OnKeyboardMsg msg ->
                    Return.map (Model.updateKeyboardState (Keyboard.update msg))
                        >> focusSelectorIfNoFocusCmd ".entity-list .focusable-list-item[tabindex=0]"

                OnSaveCurrentForm ->
                    Return.andThen Model.saveCurrentForm
                        >> andThenUpdate OnDeactivateEditingMode

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
                            andThenUpdate OnSaveCurrentForm

                        Entity.ToggleDeleted ->
                            Return.andThen (Model.toggleDeleteEntity entity)
                                >> andThenUpdate OnDeactivateEditingMode

                        Entity.ToggleArchived ->
                            Return.andThen (Model.toggleArchiveEntity entity)
                                >> andThenUpdate OnDeactivateEditingMode

                        Entity.OnFocusIn ->
                            Return.map (Model.setFocusInEntity entity)

                        Entity.ToggleSelected ->
                            Return.map (Model.toggleEntitySelection entity)

                        Entity.Goto ->
                            Return.map (Model.switchToEntityListViewFromEntity entity)

                OnLaunchBarMsgWithNow msg now ->
                    case msg of
                        LaunchBar.OnEnter entity ->
                            andThenUpdate OnDeactivateEditingMode
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
                    command (Notification.closeNotification tag)

                OnGlobalKeyUp key ->
                    onGlobalKeyUp key

                OnKeyCombo comboMsg ->
                    Return.andThen (Model.updateCombo comboMsg)

                OnTodoMsg todoMsg ->
                    withNow (OnTodoMsgWithTime todoMsg)

                OnTodoMsgWithTime todoMsg now ->
                    Task.Main.update andThenUpdate now todoMsg

                OnAppDrawerMsg msg ->
                    AppDrawer.Main.update andThenUpdate msg

                OnPersistLocalPref ->
                    Return.effect_ (Model.encodeLocalPref >> persistLocalPref)
           )
        >> Return.map (logMsg msg)


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


logMsg msg model =
    let
        _ =
            case msg of
                OnNowChanged _ ->
                    Nothing

                OnTodoMsg Todo.Msg.UpdateTimeTracker ->
                    Nothing

                OnTodoMsgWithTime Todo.Msg.UpdateTimeTracker _ ->
                    Nothing

                _ ->
                    let
                        _ =
                            1

                        --                            Debug.log "msg" (msg)
                    in
                        Nothing
    in
        model


map =
    Return.map


modelTapLog =
    Ext.Debug.tapLog >>> Return.map


updateTodoAndMaybeAlsoSelected action todo =
    Return.andThen (Model.updateTodoAndMaybeAlsoSelected action (Document.getId todo))


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


andThenTodoMsg =
    OnTodoMsg >> andThenUpdate


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")


onUpdateNow now =
    Return.map (Model.setNow now)


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
                                        >> Return.command (Notification.closeNotification todoId)

                                ReminderOverlay.ShowSnoozeOptions ->
                                    Model.setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                ReminderOverlay.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.andThen (Model.snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (Notification.closeNotification todoId)

                                ReminderOverlay.Close ->
                                    Model.removeReminderOverlay
                                        >> Return.singleton

                                ReminderOverlay.MarkDone ->
                                    Model.updateTodo Todo.MarkDone todoId
                                        >> Tuple.mapFirst Model.removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

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
                ( key, ExclusiveMode.None ) ->
                    case key of
                        Key.Escape ->
                            Return.map (Model.clearSelection)

                        Key.CharQ ->
                            andThenUpdate NewTodo

                        Key.CharI ->
                            andThenUpdate NewTodoForInbox

                        Key.Slash ->
                            LaunchBar.Open |> OnLaunchBarMsg |> andThenUpdate

                        _ ->
                            identity

                ( Key.Escape, _ ) ->
                    andThenUpdate OnDeactivateEditingMode

                _ ->
                    identity
        )


firebaseUpdateClientCmd model =
    Model.getMaybeUserId model
        ?|> Firebase.updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    Model.getMaybeUserId model
        ?|> Firebase.setupOnDisconnectCmd model.firebaseClient


positionContextMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-context-button-" ++ Document.getId todo)


positionProjectMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-project-button-" ++ Document.getId todo)


positionScheduleMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-schedule-button-" ++ Document.getId todo)


startSyncWithFirebase user =
    Return.maybeEffect (Model.getMaybeUserId >>? Firebase.startSyncCmd)
