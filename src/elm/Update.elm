port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusSelectorIfNoFocusCmd)
import Entity
import Entity.Main
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Main
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Firebase.Main
import LaunchBar.Messages
import LaunchBar.Models exposing (SearchItem(..))
import LocalPref
import Main.Update
import Material
import Menu
import Model.Internal exposing (deactivateEditingMode, setEditMode, setTodoEditForm, updateEditModeM)
import Model.Keyboard
import Model.Msg
import Model.Selection
import Model.ViewType
import Msg exposing (..)
import Stores
import Todo.Form
import TodoMsg
import Update.ExMode
import Update.LaunchBar
import Update.Subscription
import X.Keyboard as Keyboard exposing (Key)
import X.Return as Return
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Form
import Todo.Msg
import Return
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import LaunchBar.Update
import Tuple2
import Types exposing (AppModel, ModelF, Return, ReturnF)
import Toolkit.Helpers exposing (..)
import X.Record exposing (maybeOver)


map =
    Return.map


update :
    (Msg -> ReturnF)
    -> Msg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubMsg subMsg ->
            Update.Subscription.onSubMsg andThenUpdate subMsg

        OnStartExclusiveMode exclusiveMode ->
            ExclusiveMode.Main.start exclusiveMode

        OnMainMsg mainMsg ->
            Main.Update.update andThenUpdate mainMsg

        OnShowMainMenu ->
            map (setEditMode (Menu.initState |> XMMainMenu))
                >> Return.command positionMainMenuCmd

        OnEntityListKeyDown entityList { key, isShiftDown } ->
            case key of
                Key.ArrowUp ->
                    map (moveFocusBy -1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    map (moveFocusBy 1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                _ ->
                    identity

        OnRemotePouchSync form ->
            andThenUpdate OnSaveCurrentForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnDeactivateEditingMode ->
            map (deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        OnStartEditingContext todo ->
            map
                (setEditMode (XMEditTodoContext)
                    >> createAndSetTodoEditForm todo
                )
                >> Return.command (positionContextMenuCmd todo)

        OnStartEditingProject todo ->
            map
                (setEditMode (XMEditTodoProject)
                    >> createAndSetTodoEditForm todo
                )
                >> Return.command (positionProjectMenuCmd todo)

        OnNewTodoTextChanged form text ->
            map (setEditMode (Todo.Form.setNewTodoFormText text form |> XMNewTodo))

        OnStartEditingReminder todo ->
            map
                (setEditMode (XMEditTodoReminder)
                    >> createAndSetTodoEditForm todo
                )
                >> Return.command (positionScheduleMenuCmd todo)

        OnUpdateTodoForm form action ->
            map
                (setTodoEditForm (Todo.Form.update action form))
                >> autoFocusInputCmd

        OnMainMenuStateChanged menuState ->
            map
                (menuState
                    |> XMMainMenu
                    >> setEditMode
                )
                >> autoFocusInputCmd

        OnUpdateRemoteSyncFormUri form uri ->
            map
                ({ form | uri = uri }
                    |> XMEditSyncSettings
                    >> setEditMode
                )

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

        OnSaveCurrentForm ->
            Return.andThen Update.ExMode.saveCurrentForm
                >> andThenUpdate OnDeactivateEditingMode

        OnEntityMsg entityMsg ->
            Entity.Main.update andThenUpdate entityMsg

        LaunchBarMsgWithNow msg now ->
            Update.LaunchBar.update andThenUpdate msg now

        LaunchBarMsg msg ->
            withNow (LaunchBarMsgWithNow msg)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnKeyCombo comboMsg ->
            Return.andThen (Model.Keyboard.updateCombo comboMsg)

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


createAndSetTodoEditForm todo model =
    Model.Internal.setTodoEditForm (Todo.Form.create model.now todo) model


moveFocusBy : Int -> List Entity -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


command =
    Return.command


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
