port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Entity.Main
import Firebase.Main
import LaunchBar.Messages exposing (LaunchBarMsg)
import LocalPref
import Material
import Model
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Msg.ViewType exposing (ViewTypeMsg(SwitchToContextsView))
import Stores
import Time exposing (Time)
import Types exposing (AppModel)
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
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        -- non delegated
        OnCommonMsg msg_ ->
            CommonMsg.update msg_

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update andThenUpdate msg_

        OnExclusiveModeMsg msg_ ->
            let
                config : Update.ExclusiveMode.Config AppMsg
                config =
                    { focusEntityList = andThenUpdate Model.setDomFocusToFocusInEntityCmd }
            in
                Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            let
                config : Update.AppHeader.Config AppMsg
                config =
                    { setXMode = XMMsg.onSetExclusiveMode >> andThenUpdate
                    }
            in
                Update.AppHeader.update config msg_

        OnCustomSyncMsg msg_ ->
            let
                config : Update.CustomSync.Config AppMsg
                config =
                    { saveXModeForm = XMMsg.onSaveExclusiveModeForm |> andThenUpdate
                    , setXMode = XMMsg.onSetExclusiveMode >> andThenUpdate
                    }
            in
                Update.CustomSync.update config msg_

        OnEntityMsg msg_ ->
            Entity.Main.update andThenUpdate msg_

        OnLaunchBarMsgWithNow msg_ now ->
            let
                createConfig : AppModel -> Update.LaunchBar.Config AppMsg AppModel
                createConfig =
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
            in
                returnWith
                    createConfig
                    (\config -> Update.LaunchBar.update config msg_)

        OnLaunchBarMsg msg_ ->
            OnLaunchBarMsgWithNow msg_ |> returnWithNow

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            let
                config : Update.Todo.Config AppMsg
                config =
                    { switchToContextsView = switchToContextsViewMsg |> andThenUpdate
                    , setFocusInEntityWithTodoId =
                        (\todoId ->
                            -- todo: things concerning todoId should probably be moved into todo update module
                            map (Stores.setFocusInEntityWithTodoId todoId)
                                >> andThenUpdate Model.setDomFocusToFocusInEntityCmd
                        )
                    , setFocusInEntity =
                        (\entity ->
                            map (Stores.setFocusInEntity entity)
                                >> andThenUpdate Model.setDomFocusToFocusInEntityCmd
                        )
                    , closeNotification = Msg.OnCloseNotification >> andThenUpdate
                    , afterTodoUpdate =
                        XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                            |> andThenUpdate
                    , setXMode =
                        XMMsg.onSetExclusiveMode
                            >> andThenUpdate
                    }
            in
                Update.Todo.update config now msg_

        OnFirebaseMsg msg_ ->
            Firebase.Main.update andThenUpdate msg_

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg


port persistLocalPref : D.Value -> Cmd msg


onViewTypeMsg : AndThenUpdate -> ViewTypeMsg -> ReturnF
onViewTypeMsg andThenUpdate msg =
    let
        config : Update.MainViewType.Config AppMsg
        config =
            { clearSelection = map Model.Selection.clearSelection }
    in
        Update.MainViewType.update config msg


onLaunchBarMsgWithNow : AndThenUpdate -> LaunchBarMsg -> Time -> ReturnF
onLaunchBarMsgWithNow andThenUpdate msg_ now =
    let
        createConfig : AppModel -> Update.LaunchBar.Config AppMsg AppModel
        createConfig =
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
    in
        returnWith
            createConfig
            (\config -> Update.LaunchBar.update config msg_)
