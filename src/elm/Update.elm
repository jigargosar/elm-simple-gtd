module Update exposing (update)

import CommonMsg
import LocalPref
import Material
import Msg exposing (..)
import Ports
import Types.AppModel exposing (AppModel)
import Update.AppDrawer
import Update.AppHeader
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.LaunchBar
import Update.Page
import Update.Subscription
import Update.Todo
import Update.Types exposing (UpdateConfig)
import X.Return exposing (..)


update : UpdateConfig AppMsg -> AppMsg -> ReturnF AppMsg AppModel
update config msg =
    let
        onPersistLocalPref =
            effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
    in
    case msg of
        OnMdl msg_ ->
            andThen (Material.update config.onMdl msg_)

        OnPageMsg msg_ ->
            Update.Page.update config msg_

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            Update.GroupDoc.update config msg_
                >> returnMsgAsCmd Msg.updateEntityListCursorMsg

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            Update.LaunchBar.update config now msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (config.onLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (config.onTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_
                >> returnMsgAsCmd Msg.updateEntityListCursorMsg

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref
