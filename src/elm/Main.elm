module Main exposing (main)

import AppDrawer.Types exposing (AppDrawerMsg(..))
import Keyboard
import Models.AppModel exposing (Flags)
import Msg exposing (AppMsg)
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
import Update
import Update.Config
import View
import View.Config
import Window


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


init =
    Models.AppModel.createAppModel
        >> update Msg.onSwitchToNewUserSetupModeIfNeeded


update : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
update msg model =
    (model ! []) |> Update.update (Update.Config.updateConfig model) msg


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages View.Config.viewConfig
        , init = init
        , update = update
        , view = View.init View.Config.viewConfig
        , subscriptions = subscriptions
        }
