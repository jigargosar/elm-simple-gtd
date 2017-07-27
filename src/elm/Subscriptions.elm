module Subscriptions exposing (subscriptions)

import Keyboard
import Msg.Subscription exposing (SubscriptionMsg)
import Ports
import Time
import Types exposing (AppModel)


subscriptions : AppModel -> Sub SubscriptionMsg
subscriptions model =
    Sub.batch
        [ Time.every (Time.second * model.config.oneSecond) Msg.Subscription.OnNowChanged
        , Keyboard.ups Msg.Subscription.OnGlobalKeyUp
        , Ports.pouchDBChanges (uncurry Msg.Subscription.OnPouchDBChange)
        , Ports.onFirebaseDatabaseChange (uncurry Msg.Subscription.OnFirebaseDatabaseChange)
        ]
