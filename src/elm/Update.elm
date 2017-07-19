module Update exposing (update)

import Update.AppDrawer
import CommonMsg
import Model.GroupDocStore
import Ports
import Update.Firebase
import LocalPref
import Material
import Update.AppHeader
import Update.ExclusiveMode
import Update.LaunchBar
import Update.Subscription
import X.Return as Return exposing (returnWith, returnWithNow)
import Notification
import Return exposing (andThen, command, map)
import Toolkit.Operators exposing (..)
import Lazy
import Model.EntityList
import Model.Stores
import TodoMsg
import Update.Entity
import Model
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Update.CustomSync
import Update.ViewType
import Update.Todo
import Update.GroupDoc


{-
   type alias ReturnF =
       Return.ReturnF AppMsg AppModel


   type alias AndThenUpdate =
       AppMsg -> ReturnF
-}
{-
   update :
       (AppMsg -> Return.ReturnF AppMsg AppModel)
       -> AppMsg
       -> Return.ReturnF AppMsg AppModel
-}


update config andThenUpdate msg =
    case msg of
        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnViewTypeMsg msg_ ->
            Update.ViewType.update config msg_

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> Ports.persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

        OnGroupDocMsg msg_ ->
            returnWith identity
                (\oldModel ->
                    Update.GroupDoc.update msg_
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
            let
                configWithNow =
                    { config | now = now }
            in
                Update.LaunchBar.update configWithNow msg_

        OnLaunchBarMsg msg_ ->
            returnWithNow (OnLaunchBarMsgWithNow msg_)

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            let
                config model =
                    { switchToContextsView = Msg.switchToContextsViewMsg |> andThenUpdate
                    , setFocusInEntityWithEntityId =
                        -- later: create and move focusInEntity related methods to corresponding update
                        (\entityId ->
                            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
                        )
                    , setFocusInEntity =
                        (\entity ->
                            map (Model.setFocusInEntity entity)
                                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
                        )
                    , closeNotification = Msg.OnCloseNotification >> andThenUpdate
                    , afterTodoUpdate = Msg.revertExclusiveMode |> andThenUpdate
                    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
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
                config =
                    { onStartSetupAddTodo = andThenUpdate TodoMsg.onStartSetupAddTodo
                    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
                    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
                    , onSwitchToNewUserSetupModeIfNeeded =
                        andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded
                    }
            in
                Update.Firebase.update config msg_
                    >> andThenUpdate Msg.OnPersistLocalPref

        OnAppDrawerMsg msg ->
            Update.AppDrawer.update msg
                >> andThenUpdate Msg.OnPersistLocalPref
