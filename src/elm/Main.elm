module Main exposing (main)

import Models.AppModel exposing (Flags)
import Msg exposing (AppMsg)
import RouteUrl
import Routes
import Subscriptions
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Types.AppModel exposing (AppModel)
import Update
import Update.Config
import View
import View.Config


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        subscriptions model =
            Sub.batch
                [ Subscriptions.subscriptions model |> Sub.map Msg.OnSubscriptionMsg
                , Subscriptions.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
                , Subscriptions.Firebase.subscriptions model |> Sub.map Msg.OnFirebaseMsg
                , Subscriptions.AppDrawer.subscriptions model |> Sub.map Msg.OnAppDrawerMsg
                ]

        init =
            Models.AppModel.createAppModel
                >> update Msg.onSwitchToNewUserSetupModeIfNeeded

        update : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update msg model =
            (model ! []) |> Update.update (Update.Config.updateConfig model) msg
    in
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages View.Config.viewConfig
        , init = init
        , update = update
        , view = View.init View.Config.viewConfig
        , subscriptions = subscriptions
        }
