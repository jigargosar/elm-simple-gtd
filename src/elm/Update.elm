port module Update exposing (..)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusInputCmd, focusSelectorIfNoFocusCmd)
import Entity.Main
import ExclusiveMode
import Entity
import Firebase.Main
import X.Debug
import X.Keyboard as Keyboard exposing (Key)
import X.Record as Record exposing (set)
import X.Return as Return
import Firebase
import Keyboard.Combo
import LaunchBar
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Model
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


type alias Return =
    Return.Return Msg Model


type alias ReturnTuple a =
    Return.Return Msg ( a, Model )


type alias ReturnF =
    Return -> Return


over =
    Record.over >>> map


set =
    Record.set >>> map


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

        OnShowMainMenu ->
            map Model.showMainMenu

        OnEntityListKeyDown entityList { key, isShiftDown } ->
            case key of
                Key.ArrowUp ->
                    Return.map (Model.moveFocusBy -1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    Return.map (Model.moveFocusBy 1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                _ ->
                    identity

        RemotePouchSync form ->
            andThenUpdate OnSaveCurrentForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        ToggleShowDeletedEntity ->
            Return.map ((\m -> { m | showDeleted = not m.showDeleted }))

        ReminderOverlayAction action ->
            reminderOverlayAction action

        OnDeactivateEditingMode ->
            Return.map (Model.deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        StartEditingContext todo ->
            Return.map (Model.startEditingTodoContext todo)
                >> Return.command (positionContextMenuCmd todo)

        StartEditingProject todo ->
            Return.map (Model.startEditingTodoProject todo)
                >> Return.command (positionProjectMenuCmd todo)

        NewTodoTextChanged form text ->
            Return.map (Model.updateNewTodoText form text)

        StartEditingReminder todo ->
            Return.map (Model.startEditingReminder todo)
                >> Return.command (positionScheduleMenuCmd todo)

        UpdateTodoForm form action ->
            Return.map
                (Todo.Form.set action form
                    |> ExclusiveMode.EditTodo
                    >> Model.setEditMode
                )

        OnEditTodoProjectMenuStateChanged form menuState ->
            Return.map
                (Todo.GroupForm.setMenuState menuState form
                    |> ExclusiveMode.EditTodoProject
                    >> Model.setEditMode
                )
                >> autoFocusInputCmd

        OnMainMenuStateChanged menuState ->
            Return.map
                (menuState
                    |> ExclusiveMode.MainMenu
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


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


map =
    Return.map


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
            Return.map (Model.setNow now)

        OnKeyboardMsg msg ->
            Return.map (Model.updateKeyboardState (Keyboard.update msg))
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


positionContextMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-context-button-" ++ Document.getId todo)


positionProjectMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-project-button-" ++ Document.getId todo)


positionScheduleMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-schedule-button-" ++ Document.getId todo)


port syncWithRemotePouch : String -> Cmd msg


port persistLocalPref : D.Value -> Cmd msg
