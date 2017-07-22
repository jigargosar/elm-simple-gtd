module Msg.Subscription exposing (..)

import Json.Encode as E
import Time exposing (Time)


type SubscriptionMsg
    = OnNowChanged Time
    | OnGlobalKeyUp Int
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
