port module Main exposing (..)

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
import Http
import Keyboard.Combo
import LaunchBar
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Model as Model
import Notification exposing (Response)
import Todo.Notification.Model
import Routes
import Store
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


subscriptions : Model -> Sub Model.Msg
subscriptions m =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) OnNowChanged
            , Keyboard.subscription OnKeyboardMsg
            , Keyboard.ups OnGlobalKeyUp
            , Store.onChange OnPouchDBChange
            , Firebase.onChange OnFirebaseDatabaseChange
            ]
            |> Sub.map OnSubMsg
        , Keyboard.Combo.subscriptions m.keyComboModel
        , Todo.Main.subscriptions m
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
        >> updateInner msg


updateInner msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubMsg subMsg ->
            onSubMsg subMsg

        OnEntityUpsert entity ->
            case entity of
                Entity.Todo model ->
                    Todo.Msg.Upsert model |> andThenTodoMsg

                _ ->
                    identity

        OnSwitchToNewUserSetupModeIfNeeded ->
            Return.map (Model.switchToNewUserSetupModeIfNeeded)

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


updateTodoAndMaybeAlsoSelected action todo =
    Return.andThen (Model.updateTodoAndMaybeAlsoSelected action (Document.getId todo))


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
            Return.andThenMaybe
                (Model.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                    >>? Tuple.mapFirst OnEntityUpsert
                    >>? uncurry update
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
