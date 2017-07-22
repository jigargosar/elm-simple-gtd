module Msg.Subscription exposing (..)

import Json.Encode as E
import Time exposing (Time)
import X.Keyboard


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
