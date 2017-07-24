module Update exposing (update)

import CommonMsg
import Lazy
import LocalPref
import Material
import Model
import Model.EntityList
import Model.Selection
import Model.Stores
import Msg exposing (..)
import Notification
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


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


update :
    AppMsg
    -> ReturnF
update msg =
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

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            let
                config : Update.Subscription.Config AppMsg
                config =
                    { noop = Msg.noop
                    , onStartAddingTodoToInbox =
                        TodoMsg.onStartAddingTodoToInbox
                    , onStartAddingTodoWithFocusInEntityAsReference =
                        TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
                    , openLaunchBarMsg = Msg.openLaunchBarMsg
                    , revertExclusiveMode = Msg.revertExclusiveMode
                    , afterTodoUpsert = TodoMsg.afterTodoUpsert
                    }
            in
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
                config : Update.AppHeader.Config AppMsg AppModel
                config =
                    { setXMode = Msg.onSetExclusiveMode >> update
                    }
            in
            Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            let
                config : Update.CustomSync.Config AppMsg AppModel
                config =
                    { saveXModeForm = Msg.onSaveExclusiveModeForm |> update
                    , setXMode = Msg.onSetExclusiveMode >> update
                    }
            in
            Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            let
                config : Update.Entity.Config AppMsg
                config =
                    { onSetExclusiveMode = Msg.onSetExclusiveMode
                    , revertExclusiveMode = Msg.revertExclusiveMode
                    , switchToEntityListView = Msg.switchToEntityListView
                    , setDomFocusToFocusInEntityCmd =
                        Msg.setDomFocusToFocusInEntityCmd
                    , onStartEditingTodo = TodoMsg.onStartEditingTodo
                    }
            in
            Update.Entity.update config msg_

        OnLaunchBarMsgWithNow msg_ now ->
            let
                config : Update.LaunchBar.Config AppMsg
                config =
                    { now = now
                    , onComplete = Msg.revertExclusiveMode
                    , setXMode = Msg.onSetExclusiveMode
                    , onSwitchView = Msg.switchToEntityListView
                    }
            in
            Update.LaunchBar.update config msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            let
                config : AppModel -> Update.Todo.Config AppMsg AppModel
                config model =
                    { switchToContextsView = Msg.switchToContextsViewMsg |> update
                    , setFocusInEntityWithEntityId =
                        \entityId ->
                            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                                >> update Msg.setDomFocusToFocusInEntityCmd
                    , setFocusInEntity =
                        \entity ->
                            map (Model.setFocusInEntity entity)
                                >> update Msg.setDomFocusToFocusInEntityCmd
                    , closeNotification = Msg.OnCloseNotification >> update
                    , afterTodoUpdate = Msg.revertExclusiveMode |> update
                    , setXMode = Msg.onSetExclusiveMode >> update
                    , currentViewEntityList = Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
                    }
            in
            returnWith identity
                (\oldModel ->
                    Update.Todo.update (config oldModel) now msg_
                        >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
                )

        OnFirebaseMsg msg_ ->
            let
                config : Update.Firebase.Config AppMsg
                config =
                    { onStartSetupAddTodo = TodoMsg.onStartSetupAddTodo
                    , revertExclusiveMode = Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode
                    }
            in
            Update.Firebase.update config msg_
                >> onPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> onPersistLocalPref


onPersistLocalPref =
    effect (LocalPref.encodeLocalPref >> Ports.persistLocalPref)
