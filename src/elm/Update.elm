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
            withNow (LaunchBarMsgWithNow msg)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnTodoMsg todoMsg ->
            withNow (OnTodoMsgWithNow todoMsg)

        OnTodoMsgWithNow todoMsg now ->
            Todo.Main.update andThenUpdate now todoMsg

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


withNow : (Time -> AppMsg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


command =
    Return.command


port persistLocalPref : D.Value -> Cmd msg
