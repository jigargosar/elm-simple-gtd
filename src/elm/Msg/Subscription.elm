module Msg.Subscription exposing (..)

import Time exposing (Time)
import X.Keyboard
import Json.Encode as E


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg X.Keyboard.Msg
    | OnGlobalKeyUp X.Keyboard.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
