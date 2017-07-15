port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Document.Types exposing (getDocId)
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd, focusSelectorIfNoFocusRCmd)
import Entity
import Entity.Main
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Types exposing (..)
import Firebase.Main
import LocalPref
import Main.Update
import Material
import Menu
import Model.Keyboard
import Model.ViewType
import Msg exposing (..)
import Stores
import Todo.Form
import Todo.FormTypes exposing (..)
import Update.LaunchBar
import Update.Subscription
import X.Return as Return
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Form
import Return exposing (andThen)
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import Types exposing (AppModel, ModelF, Return, ReturnF)
import X.Record exposing (maybeOver)
import XMMsg


foo =
    2


map =
    Return.map


update :
    (AppMsg -> ReturnF)
    -> AppMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update andThenUpdate msg_

        OnMainMsg mainMsg ->
            Main.Update.update andThenUpdate mainMsg

        OnShowMainMenu ->
            andThenUpdate (XMMsg.onSetExclusiveMode (XMMainMenu Menu.initState))
                >> Return.command positionMainMenuCmd

        OnMainMenuStateChanged menuState ->
            (menuState
                |> XMMainMenu
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate
            )
                >> autoFocusInputRCmd

        OnRemotePouchSync form ->
            andThenUpdate XMMsg.onSaveExclusiveModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateRemoteSyncFormUri form uri ->
            { form | uri = uri }
                |> XMEditSyncSettings
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnMdl msg_ ->
            Return.andThen (Material.update OnMdl msg_)

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

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
            withNow (OnTodoMsgWithNow todoMsg)

        OnTodoMsgWithNow todoMsg now ->
            Todo.Main.update andThenUpdate now todoMsg

        OnFirebaseMsg firebaseMsg ->
            Firebase.Main.update andThenUpdate firebaseMsg

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


moveFocusBy : Int -> List Entity -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity


withNow : (Time -> AppMsg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


command =
    Return.command


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"


port syncWithRemotePouch : String -> Cmd msg


port persistLocalPref : D.Value -> Cmd msg
