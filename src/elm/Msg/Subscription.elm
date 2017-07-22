module Msg.Subscription exposing (..)

import Json.Encode as E
import Keyboard.Extra
import Time exposing (Time)


type SubscriptionMsg
    = OnNowChanged Time
    | OnKeyboardMsg Keyboard.Extra.Msg
    | OnGlobalKeyUp Keyboard.Extra.Key
    | OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value
