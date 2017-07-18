module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Ports
import Firebase.Main
import LocalPref
import Material
import Msg exposing (..)
import Types exposing (AppModel)
import Update.AppHeader
import Update.ExclusiveMode
import Update.Subscription
import X.Return as Return exposing (returnWith, returnWithNow)
import Notification
import Return exposing (andThen, command, map)
import Msg
import Update.Internal exposing (..)


update :
    AndThenUpdate
    -> AppMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            onViewTypeMsg andThenUpdate msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> Ports.persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update andThenUpdate msg_

        OnGroupDocMsg msg_ ->
            onGroupDocMsg msg_

        OnExclusiveModeMsg msg_ ->
            let
                config : Update.ExclusiveMode.Config AppMsg AppModel
                config =
                    { focusEntityList = andThenUpdate Msg.setDomFocusToFocusInEntityCmd
                    , saveTodoForm = Msg.onSaveTodoForm >> andThenUpdate
                    , saveGroupDocForm = Msg.onSaveGroupDocForm >> andThenUpdate
                    }
            in
                Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            let
                config : Update.AppHeader.Config AppMsg AppModel
                config =
                    { setXMode = Msg.onSetExclusiveMode >> andThenUpdate
                    }
            in
                Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            onCustomSyncMsg andThenUpdate msg_

        OnEntityMsg msg_ ->
            onEntityMsg andThenUpdate msg_

        OnLaunchBarMsgWithNow msg_ now ->
            onLaunchBarMsgWithNow andThenUpdate msg_ now

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            onTodoMsgWithNow andThenUpdate msg_ now

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg
