module Subscriptions exposing (..)

import Msg
import Msg.Subscription
import Ports exposing (onFirebaseDatabaseChangeSub)
import Store
import Subscriptions.AppDrawer
import Subscriptions.Firebase
import Subscriptions.Todo
import Time
import Types exposing (AppModel)
import X.Keyboard


subscriptions : AppModel -> Sub Msg.AppMsg
subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Msg.Subscription.OnNowChanged
            , X.Keyboard.subscription Msg.Subscription.OnKeyboardMsg
            , X.Keyboard.ups Msg.Subscription.OnGlobalKeyUp
            , Store.onChange Msg.Subscription.OnPouchDBChange
            , onFirebaseDatabaseChangeSub Msg.Subscription.OnFirebaseDatabaseChange
            ]
            |> Sub.map Msg.OnSubscriptionMsg
        , Subscriptions.Todo.subscriptions model |> Sub.map Msg.OnTodoMsg
        , Subscriptions.Firebase.subscriptions model |> Sub.map Msg.OnFirebaseMsg
        , Subscriptions.AppDrawer.subscriptions model |> Sub.map Msg.OnAppDrawerMsg
        ]
