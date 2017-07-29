module Msg.Firebase exposing (..)

import Json.Encode as E


type FirebaseMsg
    = OnFB_NOOP
    | OnFB_SwitchToNewUserSetupModeIfNeeded
    | OnFBSignIn
    | OnFBSignOut
    | OnFBAfterUserChanged
    | OnFBSkipSignIn
    | OnFBUserChanged E.Value
    | OnFBFCMTokenChanged E.Value
    | OnFBConnectionChanged Bool
