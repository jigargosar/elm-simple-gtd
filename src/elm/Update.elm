module Update exposing (Config, update)

import CommonMsg
import Lazy
import LocalPref
import Material
import Model
import Model.EntityList
import Model.Stores
import Msg exposing (..)
import Ports
import Return
import TodoMsg
import Types exposing (..)
import Update.AppDrawer
import Update.AppHeader
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


type alias ReturnF msg =
    Return.ReturnF msg AppModel


type alias Config msg =
    Update.Firebase.Config msg (Update.CustomSync.Config msg (Update.Entity.Config msg (Update.Subscription.Config msg {})))


update :
    Config AppMsg
    -> AppMsg
    -> ReturnF AppMsg
update config msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            let
                config : Update.ViewType.Config AppMsg
                config =
                    { noop = Msg.noop }
            in
            Update.ViewType.update config msg_

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            let
                config : Update.GroupDoc.Config AppMsg
                config =
                    { revertExclusiveMode = Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode
                    }
            in
            returnWith identity
                (\oldModel ->
                    Update.GroupDoc.update config msg_
                        >> map (Model.EntityList.updateEntityListCursorOnGroupDocChange oldModel)
                )

        OnExclusiveModeMsg msg_ ->
            let
                config : Update.ExclusiveMode.Config AppMsg
                config =
                    { focusEntityList = Msg.setDomFocusToFocusInEntityCmd
                    , saveTodoForm = Msg.onSaveTodoForm
                    , saveGroupDocForm = Msg.onSaveGroupDocForm
                    }
            in
            Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            let
                config : Update.AppHeader.Config AppMsg
                config =
                    { onSetExclusiveMode = Msg.onSetExclusiveMode
                    }
            in
            Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            let
                config : Update.LaunchBar.Config AppMsg
                config =
                    { now = now
                    , onComplete = Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode
                    , onSwitchView = Msg.switchToEntityListView
                    }
            in
            Update.LaunchBar.update config msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        SetFocusInEntity entity ->
            map (Model.setFocusInEntity entity)
                >> update config Msg.setDomFocusToFocusInEntityCmd

        SetFocusInEntityWithEntityId entityId ->
            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                >> update config Msg.setDomFocusToFocusInEntityCmd

        OnTodoMsgWithNow msg_ now ->
            let
                config : AppModel -> Update.Todo.Config AppMsg
                config model =
                    { switchToContextsView = Msg.switchToContextsViewMsg
                    , setFocusInEntityWithEntityId = Msg.SetFocusInEntityWithEntityId
                    , setFocusInEntity = Msg.SetFocusInEntity
                    , revertExclusiveMode = Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode
                    , currentViewEntityList = Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
                    }
            in
            returnWith identity
                (\oldModel ->
                    Update.Todo.update (config oldModel) now msg_
                        >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
                )

        OnFirebaseMsg msg_ ->
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref


onPersistLocalPref =
    effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
