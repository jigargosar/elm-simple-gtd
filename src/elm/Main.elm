module Main exposing (main)

import Model.Internal exposing (Flags)
import Msg exposing (AppMsg)
import RouteUrl
import Routes
import Subscriptions
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Types exposing (..)
import Update
import Update.Config
import Update.Types exposing (UpdateConfig)
import View
import View.Config
import X.Return exposing (..)


type alias AppReturn =
    Return AppMsg AppModel


subscriptions : AppModel -> Sub Msg.AppMsg
subscriptions model =
    Sub.batch
        [ Subscriptions.subscriptions |> Sub.map Msg.OnSubscriptionMsg
        , Subscriptions.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
        , Subscriptions.Firebase.subscriptions model |> Sub.map Msg.OnFirebaseMsg
        , Subscriptions.AppDrawer.subscriptions model |> Sub.map Msg.OnAppDrawerMsg
        ]


init : Flags -> AppReturn
init =
    Model.Internal.createAppModel
        >> update Msg.onSwitchToNewUserSetupModeIfNeeded


update : AppMsg -> AppModel -> AppReturn
update msg model =
    pure model |> Update.update (Update.Config.updateConfig model) msg


main : RouteUrl.RouteUrlProgram Flags AppModel Msg.AppMsg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages View.Config.viewConfig
        , init = init
        , update = update
        , view = View.init View.Config.viewConfig
        , subscriptions = subscriptions
        }
