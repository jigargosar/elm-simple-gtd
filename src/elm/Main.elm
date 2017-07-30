module Main exposing (main)

import AppDrawer.Types exposing (AppDrawerMsg(..))
import CommonMsg
import Keyboard
import LocalPref
import Material
import Models.AppModel exposing (Flags)
import Msg exposing (..)
import Msg.Firebase exposing (..)
import Msg.Subscription exposing (..)
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import RouteUrl
import Routes
import Time
import Todo.Msg exposing (..)
import Types.AppModel exposing (..)
import Update.AppDrawer
import Update.AppHeader
import Update.Config
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.GroupDoc
import Update.LaunchBar
import Update.Page
import Update.Subscription
import Update.Todo
import Update.Types exposing (..)
import View
import View.Config
import Window
import X.Return exposing (..)


subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1 * model.config.debugSecondMultiplier) Msg.Subscription.OnNowChanged
            , Keyboard.ups Msg.Subscription.OnGlobalKeyUp
            , Keyboard.downs Msg.Subscription.OnGlobalKeyDown
            , Ports.pouchDBChanges (uncurry Msg.Subscription.OnPouchDBChange)
            , Ports.onFirebaseDatabaseChange (uncurry Msg.Subscription.OnFirebaseDatabaseChange)
            ]
            |> Sub.map Msg.OnSubscriptionMsg
        , Sub.batch
            [ notificationClicked OnReminderNotificationClicked
            , onRunningTodoNotificationClicked RunningNotificationResponse
            , Time.every (Time.second * 1 * model.config.debugSecondMultiplier) (\_ -> UpdateTimeTracker)
            , Time.every (Time.second * 30 * model.config.debugSecondMultiplier) (\_ -> OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map Msg.OnTodoMsg
        , Sub.batch
            [ onFirebaseUserChanged OnFBUserChanged
            , onFCMTokenChanged OnFBFCMTokenChanged
            , onFirebaseConnectionChanged OnFBConnectionChanged
            ]
            |> Sub.map Msg.OnFirebaseMsg
        , Sub.batch
            [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
            |> Sub.map Msg.OnAppDrawerMsg
        ]


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


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        init =
            Models.AppModel.createAppModel
                >> update_ Msg.onSwitchToNewUserSetupModeIfNeeded

        update_ : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update_ msg model =
            model |> pure >> update (Update.Config.updateConfig model) msg
    in
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages View.Config.viewConfig
        , init = init
        , update = update_
        , view = View.init View.Config.viewConfig
        , subscriptions = subscriptions
        }
