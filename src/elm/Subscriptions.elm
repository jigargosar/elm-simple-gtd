module Subscriptions exposing (subscriptions)

import Keyboard
import Msg.Subscription exposing (SubscriptionMsg)
import Ports
import Time


subscriptions : Sub SubscriptionMsg
subscriptions =
    Sub.batch
        [ Time.every (Time.second * 1) Msg.Subscription.OnNowChanged
        , Keyboard.ups Msg.Subscription.OnGlobalKeyUp
        , Ports.pouchDBChanges (uncurry Msg.Subscription.OnPouchDBChange)
        , Ports.onFirebaseDatabaseChange (uncurry Msg.Subscription.OnFirebaseDatabaseChange)
        ]
