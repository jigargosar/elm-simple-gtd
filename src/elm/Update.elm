port module Update exposing (..)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusSelectorIfNoFocusCmd)
import Entity.Main
import ExclusiveMode
import Entity
import ExclusiveMode.Main
import Firebase.Main
import Material
import Toolkit.Helpers exposing (apply2)
import X.Debug
import X.Keyboard as Keyboard exposing (Key)
import X.Record as Record exposing (set)
import X.Return as Return
import Firebase
import Keyboard.Combo
import LaunchBar
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Notification.Model
import Todo
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Model exposing (..)
import Todo.Main
import View
import Json.Decode as D exposing (Decoder)
import LaunchBar.Main
import Tuple2


map =
    Return.map


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> updateInner msg


updateInner msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubMsg subMsg ->
            onSubMsg subMsg

        OnStartExclusiveMode exclusiveMode ->
            ExclusiveMode.Main.start exclusiveMode

        OnShowMainMenu ->
            map Model.showMainMenu
                >> Return.command positionMainMenuCmd

        OnEntityListKeyDown entityList { key, isShiftDown } ->
            case key of
                Key.ArrowUp ->
                    map (Model.moveFocusBy -1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    map (Model.moveFocusBy 1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                _ ->
                    identity

        RemotePouchSync form ->
            andThenUpdate OnSaveCurrentForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        ReminderOverlayAction action ->
            reminderOverlayAction action

        OnDeactivateEditingMode ->
            map (Model.deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        StartEditingContext todo ->
            map (Model.startEditingTodoContext todo)
                >> Return.command (positionContextMenuCmd todo)

        StartEditingProject todo ->
            map (Model.startEditingTodoProject todo)
                >> Return.command (positionProjectMenuCmd todo)

        NewTodoTextChanged form text ->
            map (Model.updateNewTodoText form text)

        StartEditingReminder todo ->
            map (Model.startEditingReminder todo)
                >> Return.command (positionScheduleMenuCmd todo)

        UpdateTodoForm form action ->
            map
                (Todo.Form.set action form
                    |> ExclusiveMode.EditTodo
                    >> Model.setEditMode
                )

        OnEditTodoProjectMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> ExclusiveMode.EditTodoProject
                    >> Model.setEditMode
                )
                >> autoFocusInputCmd

        OnMainMenuStateChanged menuState ->
            map
                (menuState
                    |> ExclusiveMode.MainMenu
                    >> Model.setEditMode
                )
                >> autoFocusInputCmd

        OnEditTodoContextMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> ExclusiveMode.EditTodoContext
                    >> Model.setEditMode
                )
                >> autoFocusInputCmd

        UpdateRemoteSyncFormUri form uri ->
            map
                ({ form | uri = uri }
                    |> ExclusiveMode.EditSyncSettings
                    >> Model.setEditMode
                )

        OnSetViewType viewType ->
            map (Model.switchToView viewType)

        OnSaveCurrentForm ->
            Return.andThen Model.saveCurrentForm
                >> andThenUpdate OnDeactivateEditingMode

        NewTodoForInbox ->
            map (Model.activateNewTodoModeWithInboxAsReference)
                >> autoFocusInputCmd

        NewProject ->
            map Model.createAndEditNewProject
                >> autoFocusInputCmd

        NewContext ->
            map Model.createAndEditNewContext
                >> autoFocusInputCmd

        OnEntityMsg entity entityMsg ->
            Entity.Main.update andThenUpdate entity entityMsg

        OnLaunchBarMsgWithNow msg now ->
            LaunchBar.Main.update andThenUpdate now msg

        OnLaunchBarMsg msg ->
            withNow (OnLaunchBarMsgWithNow msg)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnKeyCombo comboMsg ->
            Return.andThen (Model.updateCombo comboMsg)

        OnTodoMsg todoMsg ->
            withNow (OnTodoMsgWithTime todoMsg)

        OnTodoMsgWithTime todoMsg now ->
            Todo.Main.update andThenUpdate now todoMsg

        OnFirebaseMsg firebaseMsg ->
            Firebase.Main.update andThenUpdate firebaseMsg

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg

        OnPersistLocalPref ->
            Return.effect_ (Model.encodeLocalPref >> persistLocalPref)

        Mdl msg_ ->
            Return.andThen (Material.update Mdl msg_)


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Model.updateTodoAndMaybeAlsoSelected action todoId)


andThenUpdate =
    update >> Return.andThen


andThenTodoMsg =
    OnTodoMsg >> andThenUpdate


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


reminderOverlayAction action =
    Return.andThen
        (\model ->
            model
                |> case model.reminderOverlay of
                    Todo.Notification.Model.Active activeView todoDetails ->
                        let
                            todoId =
                                todoDetails.id
                        in
                            case action of
                                Todo.Notification.Model.Dismiss ->
                                    Model.updateTodo (Todo.TurnReminderOff) todoId
                                        >> Tuple.mapFirst Model.removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.ShowSnoozeOptions ->
                                    Model.setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                Todo.Notification.Model.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.andThen (Model.snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.Close ->
                                    Model.removeReminderOverlay
                                        >> Return.singleton

                                Todo.Notification.Model.MarkDone ->
                                    Model.updateTodo Todo.MarkDone todoId
                                        >> Tuple.mapFirst Model.removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                    _ ->
                        Return.singleton
        )


command =
    Return.command


onSubMsg subMsg =
    case subMsg of
        OnNowChanged now ->
            map (Model.setNow now)

        OnKeyboardMsg msg ->
            map (Model.updateKeyboardState (Keyboard.update msg))
                >> focusSelectorIfNoFocusCmd ".entity-list .focusable-list-item[tabindex=0]"

        OnGlobalKeyUp key ->
            onGlobalKeyUp key

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange entity =
                    case entity of
                        Entity.Todo model ->
                            Todo.Msg.Upsert model |> OnTodoMsg

                        _ ->
                            Model.noop
            in
                Return.andThenMaybe
                    (Model.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapFirst afterEntityUpsertOnPouchDBChange
                                >> uncurry update
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (Model.upsertEncodedDocOnFirebaseChange dbName encodedDoc)


onGlobalKeyUp : Key -> ReturnF
onGlobalKeyUp key =
    Return.with (Model.getEditMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, ExclusiveMode.None ) ->
                    let
                        clear =
                            map (Model.clearSelection)
                                >> andThenUpdate OnDeactivateEditingMode
                    in
                        case key of
                            Key.Escape ->
                                clear

                            Key.CharX ->
                                clear

                            Key.CharQ ->
                                Return.andThen
                                    (apply2
                                        ( Model.onNewTodoModeWithFocusInEntityAsReference
                                        , identity
                                        )
                                        >> uncurry update
                                    )

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


positionContextMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-context-button-" ++ Document.getId todo)


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"


positionProjectMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-project-button-" ++ Document.getId todo)


positionScheduleMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-schedule-button-" ++ Document.getId todo)


port syncWithRemotePouch : String -> Cmd msg


port persistLocalPref : D.Value -> Cmd msg
