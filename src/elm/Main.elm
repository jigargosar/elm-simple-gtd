port module Main exposing (..)

import CommonMsg
import Document
import Dom
import DomPorts exposing (autoFocusPaperInputCmd, focusPaperInputCmd, focusSelectorIfNoFocusCmd)
import EditMode
import Ext.Debug
import Ext.Keyboard as Keyboard exposing (Key)
import Ext.Return as Return
import Firebase
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
                    Return.map (Model.onPouchDBChange dbName encodedDoc)

                OnFirebaseChange dbName encodedDoc ->
                    Return.effect_ (Model.upsertEncodedDocCmd dbName encodedDoc)

                SignIn ->
                    Return.command (Firebase.signIn ())

                SignOut ->
                    Return.command (Firebase.signOut ())

                OnUserChanged user ->
                    Return.map (Model.setUser user)
                        >> Return.effect_ firebaseUpdateTokenCmd
                        >> startSyncWithFirebase user

                OnFCMTokenChanged token ->
                    let
                        _ =
                            Debug.log "fcm: token" (token)
                    in
                        Return.map (Model.setFCMToken token)
                            >> Return.effect_ firebaseUpdateTokenCmd

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
                    data.id |> ShowReminderOverlayForTodoId >> andThenUpdate

                ToggleShowDeletedEntity ->
                    Return.map ((\m -> { m | showDeleted = not m.showDeleted }))

                FocusPaperInput selector ->
                    focusPaperInputCmd selector

                AutoFocusPaperInput ->
                    autoFocusPaperInputCmd

                TodoAction action id ->
                    identity

                ReminderOverlayAction action ->
                    reminderOverlayAction action

                ToggleTodoDone todo ->
                    updateTodo Todo.ToggleDone todo

                SetTodoContext todoContext todo ->
                    updateTodoAndMaybeAlsoSelected (Todo.SetContext todoContext) todo
                        >> andThenUpdate DeactivateEditingMode

                SetTodoProject project todo ->
                    updateTodoAndMaybeAlsoSelected (Todo.SetProject project) todo
                        >> andThenUpdate DeactivateEditingMode

                NewTodoTextChanged text ->
                    Return.map (Model.updateNewTodoText text)

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
                        >> autoFocusPaperInputCmd

                StartEditingContext todo ->
                    Return.map (Model.startEditingContext todo)
                        >> Return.command (positionContextDropdownCmd todo)

                StartEditingProject todo ->
                    Return.map (Model.startEditingProject todo)
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
                    Return.map (Model.switchView viewType)

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
                    Return.map
                        (apply2
                            ( Model.getMaybeEditTodoReminderForm >>? .id
                            , Model.saveCurrentForm
                            )
                        )
                        >> Return.andThen
                            (apply2 ( Tuple.second, uncurry scheduleReminderNotificationForMaybeTodoIdCmd ))
                        >> andThenUpdate DeactivateEditingMode

                NewTodo ->
                    Return.map (Model.activateNewTodoMode)
                        >> autoFocusPaperInputCmd

                NewProject ->
                    Return.map Model.createAndEditNewProject
                        >> autoFocusPaperInputCmd

                NewContext ->
                    Return.map Model.createAndEditNewContext
                        >> autoFocusPaperInputCmd

                StartAddingNewEntity entityType ->
                    identity

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
                            Return.map (Model.toggleDeleteEntity entity)
                                >> andThenUpdate DeactivateEditingMode

                        SetFocusedIn ->
                            Return.map (Model.setFocusInEntity entity)

                        SetFocused ->
                            Return.map (Model.setMaybeFocusedEntity (Just entity))

                        SetBlurred ->
                            Return.map (Model.setMaybeFocusedEntity Nothing)

                        ToggleSelected ->
                            Return.map (Model.toggleEntitySelection entity)

                OnGlobalKeyUp key ->
                    onGlobalKeyUp key
           )
        >> persistAll


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


updateTodo : Todo.UpdateAction -> Todo.Model -> ReturnF
updateTodo action todo =
    Return.map (Model.updateTodo action (Document.getId todo))


updateTodoAndMaybeAllSelectedTodosIfTodoIsSelected action todo =
    Return.map (Model.updateTodoAndMaybeAlsoSelected action (Document.getId todo))


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
        >> Return.andThenMaybe
            (Model.findAndSnoozeOverDueTodo
                >>? scheduleReminderNotifications
            )


scheduleReminderNotifications ( todo, model ) =
    model ! [ showTodoNotificationCmd todo, scheduleReminderNotificationHelp todo model ]


showTodoNotificationCmd =
    createTodoNotification >> showNotification >> (::) # [ startAlarm () ] >> Cmd.batch


withNow : (Time -> Msg) -> ReturnF
withNow msg =
    Task.perform (msg) Time.now |> Return.command


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
                                        >> Model.removeReminderOverlay
                                        >> Return.singleton
                                        >> Return.command (closeNotification todoId)
                                        >> Return.effect_ (scheduleReminderNotificationCmd todoId)

                                ReminderOverlay.ShowSnoozeOptions ->
                                    Model.setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                ReminderOverlay.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.map (Model.snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (closeNotification todoId)
                                        >> Return.effect_ (scheduleReminderNotificationCmd todoId)

                                ReminderOverlay.Close ->
                                    Model.removeReminderOverlay
                                        >> Return.singleton

                                _ ->
                                    Return.singleton

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
                ( Key.Escape, EditMode.None ) ->
                    Return.map (Model.clearSelection)

                ( Key.Escape, _ ) ->
                    andThenUpdate DeactivateEditingMode

                ( Key.CharQ, EditMode.None ) ->
                    andThenUpdate NewTodo

                _ ->
                    identity
        )


firebaseUpdateTokenCmd model =
    Model.getMaybeUserId model ?|> Firebase.setTokenCmd model.deviceId # model.fcmToken ?= Cmd.none


scheduleReminderNotificationForMaybeTodoIdCmd : Maybe Todo.Id -> Model -> Cmd msg
scheduleReminderNotificationForMaybeTodoIdCmd maybeTodoId model =
    maybeTodoId
        ?|> (scheduleReminderNotificationCmd # model)
        ?= Cmd.none


scheduleReminderNotificationCmd todoId model =
    Model.findTodoById todoId model
        ?|> (scheduleReminderNotificationHelp # model)
        ?= Cmd.none


scheduleReminderNotificationHelp : Todo.Model -> Model -> Cmd msg
scheduleReminderNotificationHelp todo model =
    let
        scheduleHelp uid =
            let
                maybeTime =
                    Todo.getMaybeReminderTime todo

                todoId =
                    Document.getId todo
            in
                Firebase.scheduledReminderNotificationCmd maybeTime uid todoId
    in
        (Model.getMaybeUserId model) ?|> scheduleHelp ?= Cmd.none


positionContextDropdownCmd todo =
    DomPorts.positionDropdown ( "context-dropdown", "context-dropdown-" ++ Document.getId todo )


positionProjectDropdownCmd todo =
    DomPorts.positionDropdown ( "project-dropdown", "project-dropdown-" ++ Document.getId todo )


startSyncWithFirebase user =
    Return.maybeEffect (Model.getMaybeUserId >>? Firebase.startSyncCmd)
