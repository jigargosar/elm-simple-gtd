port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Entity.Main
import Firebase.Main
import LocalPref
import Material
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Msg.ViewType exposing (ViewTypeMsg(SwitchToContextsView))
import Stores
import Update.AppHeader
import Update.CustomSync
import Update.ExclusiveMode
import Update.LaunchBar
import Update.Subscription
import Update.MainViewType
import X.Return as Return exposing (returnWith, returnWithNow)
import Notification
import Return exposing (andThen, command, map)
import Update.Todo
import Json.Decode as D exposing (Decoder)
import ReturnTypes exposing (..)
import XMMsg


switchToContextsViewMsg =
    SwitchToContextsView |> OnViewTypeMsg


update :
    (AppMsg -> ReturnF)
    -> AppMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            let
                config =
                    { clearSelection = map Model.Selection.clearSelection }
            in
                Update.MainViewType.update config msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        -- non delegated
        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update andThenUpdate msg_

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update andThenUpdate msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update andThenUpdate msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update andThenUpdate msg_

        OnEntityMsg msg_ ->
            Entity.Main.update andThenUpdate msg_

        LaunchBarMsgWithNow msg_ now ->
            returnWith
                (\m ->
                    { now = now
                    , activeProjects = (Model.GroupDocStore.getActiveProjects m)
                    , activeContexts = (Model.GroupDocStore.getActiveContexts m)
                    , onComplete =
                        XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                            |> andThenUpdate
                    , setXMode =
                        XMMsg.onSetExclusiveMode
                            >> andThenUpdate
                    , onSwitchView =
                        Msg.switchToEntityListView
                            >> andThenUpdate
                    }
                )
                (\config -> Update.LaunchBar.updateWithConfig config msg_)

        --            Update.LaunchBar.update andThenUpdate msg_ now
        LaunchBarMsg msg_ ->
            LaunchBarMsgWithNow msg_ |> returnWithNow

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            let
                config : Update.Todo.Config
                config =
                    { switchToContextsView = switchToContextsViewMsg |> andThenUpdate
                    , setFocusInEntityWithTodoId = Stores.setFocusInEntityWithTodoId >> map
                    , setFocusInEntity = Stores.setFocusInEntity >> map
                    }
            in
                Update.Todo.update config andThenUpdate now msg_

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


port persistLocalPref : D.Value -> Cmd msg
