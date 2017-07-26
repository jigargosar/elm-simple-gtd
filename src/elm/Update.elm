module Update exposing (update)

import CommonMsg
import LocalPref
import Material
import Model.EntityList
import Msg exposing (..)
import Ports
import Types exposing (..)
import Update.AppDrawer
import Update.AppHeader
import Update.Config exposing (UpdateConfig)
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.LaunchBar
import Update.Subscription
import Update.Todo
import Update.ViewType
import X.Return exposing (..)


update :
    UpdateConfig AppMsg
    -> AppMsg
    -> ReturnF AppMsg AppModel
update config msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update config.onMdl msg_)

        OnViewTypeMsg msg_ ->
            Update.ViewType.update config msg_

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            returnWith identity
                (\oldModel ->
                    Update.GroupDoc.update config msg_
                        >> map (Model.EntityList.updateEntityListCursorOnGroupDocChange oldModel)
                )

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
            returnWith identity
                (\oldModel ->
                    Update.Todo.update config now msg_
                        >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
                )

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref


onPersistLocalPref : ReturnF AppMsg AppModel
onPersistLocalPref =
    effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
