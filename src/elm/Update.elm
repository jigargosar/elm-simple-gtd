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
import Material
import Menu
import Model.ViewType
import Msg exposing (..)
import Stores
import Todo.Form
import Todo.FormTypes exposing (..)
import Update.AppHeader
import Update.CustomSync
import Update.ExclusiveMode
import Update.LaunchBar
import Update.Subscription
import X.Return as Return exposing (returnWithNow)
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Form
import Return exposing (andThen, command, map)
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import Types exposing (AppModel, ModelF, Return, ReturnF)
import X.Record exposing (maybeOver)
import XMMsg


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

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update andThenUpdate msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update andThenUpdate msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update andThenUpdate msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

        OnEntityMsg entityMsg ->
            Entity.Main.update andThenUpdate entityMsg

        LaunchBarMsgWithNow msg now ->
            Update.LaunchBar.update andThenUpdate msg now

        LaunchBarMsg msg ->
            LaunchBarMsgWithNow msg |> returnWithNow

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnTodoMsg todoMsg ->
            returnWithNow (OnTodoMsgWithNow todoMsg)

        OnTodoMsgWithNow todoMsg now ->
            Todo.Main.update andThenUpdate now todoMsg

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


port persistLocalPref : D.Value -> Cmd msg
