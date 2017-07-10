port module Update exposing (..)

import AppDrawer.Main
import CommonMsg
import Context
import Document
import DomPorts exposing (autoFocusInputCmd, focusSelectorIfNoFocusCmd)
import Entity.Main
import Entity.Types exposing (createContextEntity, createProjectEntity)
import ExclusiveMode.Main
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Firebase.Main
import LaunchBar.Types exposing (LBMsg(OnLBOpen))
import LocalPref
import Material
import Model.ExMode
import Model.Msg
import Model.Selection
import Model.ViewType
import Msg exposing (..)
import Project
import Store
import Stores
import Todo.Notification.Types
import Todo.Types exposing (TodoAction(TA_MarkDone, TA_TurnReminderOff))
import X.Keyboard as Keyboard exposing (Key)
import X.Return as Return
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Notification.Model
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Return
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import LaunchBar.Main
import Tuple2
import Types exposing (AppModel, Return, ReturnF)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


map =
    Return.map


update : Msg -> AppModel -> Return
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
            map Model.ExMode.showMainMenu
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

        OnRemotePouchSync form ->
            andThenUpdate OnSaveCurrentForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnReminderOverlayAction action ->
            reminderOverlayAction action

        OnDeactivateEditingMode ->
            map (Model.ExMode.deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        OnStartEditingContext todo ->
            map (Model.ExMode.startEditingTodoContext todo)
                >> Return.command (positionContextMenuCmd todo)

        OnStartEditingProject todo ->
            map (Model.ExMode.startEditingTodoProject todo)
                >> Return.command (positionProjectMenuCmd todo)

        OnNewTodoTextChanged form text ->
            map (Model.ExMode.updateNewTodoText form text)

        OnStartEditingReminder todo ->
            map (Model.ExMode.startEditingReminder todo)
                >> Return.command (positionScheduleMenuCmd todo)

        OnUpdateTodoForm form action ->
            map
                (Todo.Form.set action form
                    |> XMEditTodo
                    >> Model.ExMode.setEditMode
                )

        OnEditTodoProjectMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> XMEditTodoProject
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnMainMenuStateChanged menuState ->
            map
                (menuState
                    |> XMMainMenu
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnEditTodoContextMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> XMEditTodoContext
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnUpdateRemoteSyncFormUri form uri ->
            map
                ({ form | uri = uri }
                    |> XMEditSyncSettings
                    >> Model.ExMode.setEditMode
                )

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

        OnSaveCurrentForm ->
            Return.andThen Model.ExMode.saveCurrentForm
                >> andThenUpdate OnDeactivateEditingMode

        OnEntityMsg entityMsg ->
            Entity.Main.update andThenUpdate entityMsg

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
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnMdl msg_ ->
            Return.andThen (Material.update OnMdl msg_)


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


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
                    Todo.Notification.Types.Active activeView todoDetails ->
                        let
                            todoId =
                                todoDetails.id
                        in
                            case action of
                                Todo.Notification.Model.Dismiss ->
                                    Stores.updateTodo (TA_TurnReminderOff) todoId
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
                                    Stores.updateTodo TA_MarkDone todoId
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
                        Entity.Types.TodoEntity model ->
                            Todo.Msg.Upsert model |> OnTodoMsg

                        _ ->
                            Model.noop
            in
                Return.andThenMaybe
                    (Stores.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapFirst afterEntityUpsertOnPouchDBChange
                                >> uncurry update
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (Stores.upsertEncodedDocOnFirebaseChange dbName encodedDoc)


onGlobalKeyUp : Key -> ReturnF
onGlobalKeyUp key =
    Return.with (Model.getEditMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map (Model.Selection.clearSelection)
                                >> andThenUpdate OnDeactivateEditingMode
                    in
                        case key of
                            Key.Escape ->
                                clear

                            Key.CharX ->
                                clear

                            Key.CharQ ->
                                Return.andThenApplyWith
                                    Model.Msg.onNewTodoModeWithFocusInEntityAsReference
                                    update

                            Key.CharI ->
                                andThenUpdate Msg.onNewTodoForInbox

                            Key.Slash ->
                                OnLBOpen |> OnLaunchBarMsg |> andThenUpdate

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
