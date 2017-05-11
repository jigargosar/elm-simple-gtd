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
import Model.Internal as Model
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
import Types exposing (..)
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
        [ Time.every (Time.second * 10) OnNowChanged
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.keyUps OnGlobalKeyUp
        , notificationClicked OnNotificationClicked
        , Store.onChange OnExternalEntityChanged
        ]


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> (case msg of
                OnCommonMsg msg ->
                    CommonMsg.update msg

                OnExternalEntityChanged dbName encodedDoc ->
                    Return.map (Model.onExternalEntityChange dbName encodedDoc)

                SignIn ->
                    Return.command (Firebase.signIn ())

                SignOut ->
                    Return.command (Firebase.signOut ())

                OnUserChanged user ->
                    Return.map (Model.setUser user)

                OnFCMTokenChanged token ->
                    Return.map (Model.setFCMToken token)

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
                    updateTodo (Todo.SetContext todoContext) todo

                SetTodoProject project todo ->
                    updateTodo (Todo.SetProject project) todo

                StartAddingTodo ->
                    Return.map (Model.activateNewTodoMode)
                        >> autoFocusPaperInputCmd

                NewTodoTextChanged text ->
                    Return.map (Model.updateNewTodoText text)

                NewProject ->
                    Return.map Model.createAndEditNewProject
                        >> autoFocusPaperInputCmd

                NewContext ->
                    Return.map Model.createAndEditNewContext
                        >> autoFocusPaperInputCmd

                DeactivateEditingMode ->
                    Return.map (Model.deactivateEditingMode)
                        >> andThenUpdate setDomFocusToFocusedEntityCmd

                NewTodoKeyUp { text } { key } ->
                    case key of
                        Key.Enter ->
                            andThenUpdate (SaveCurrentForm)

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

                SetView viewType ->
                    Return.map (Model.setMainViewType viewType)

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
                            Return.map (Model.toggleEntityDeleted entity)
                                >> andThenUpdate DeactivateEditingMode

                        SetFocusedIn ->
                            Return.map (Model.setFocusInEntity entity)

                        SetFocused ->
                            Return.map (Model.setMaybeFocusedEntity (Just entity))

                        --                                >> Return.map (Ext.Debug.tapLog (.maybeFocusedEntity) "maybe entity:")
                        SetBlurred ->
                            Return.map (Model.setMaybeFocusedEntity Nothing)

                        --                                >> Return.map (Ext.Debug.tapLog (.maybeFocusedEntity) "maybe entity:")
                        ToggleSelected ->
                            Return.map (Model.toggleEntitySelection entity)
                                >> Return.map (Ext.Debug.tapLog (.selectedEntityIdSet) "selectedEntityIdSet")

                OnFocusedEntityAction action ->
                    Return.withMaybe (.maybeFocusedEntity)
                        (OnEntityAction # action >> andThenUpdate)

                OnGlobalKeyUp key ->
                    onGlobalKeyUp key
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


updateTodo : Todo.UpdateAction -> Todo.Model -> ReturnF
updateTodo action todo =
    Return.map (Model.updateTodoById action (Document.getId todo))


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
        (Model.findAndSnoozeOverDueTodo >>? Tuple.mapSecond showTodoNotificationCmd)


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
                                    Model.updateTodoById (Todo.TurnReminderOff) todoId
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


command =
    Return.command


onGlobalKeyUp : Key -> ReturnF
onGlobalKeyUp key =
    Return.with (Model.getEditMode)
        (\editMode ->
            case ( key, editMode ) of
                ( Key.Escape, _ ) ->
                    andThenUpdate DeactivateEditingMode

                ( Key.CharQ, EditMode.None ) ->
                    andThenUpdate StartAddingTodo

                ( Key.CharD, EditMode.None ) ->
                    andThenUpdate (OnFocusedEntityAction ToggleDeleted)

                ( Key.CharE, EditMode.None ) ->
                    andThenUpdate (OnFocusedEntityAction StartEditing)

                _ ->
                    identity
        )
