module Firebase.Types exposing (..)

import Json.Encode as E


type FirebaseMsg
    = OnFBNOOP
    | OnFBSignIn
    | OnFBSignOut
    | OnFBAfterUserChanged
    | OnFBSkipSignIn
    | OnFBUserChanged E.Value
    | OnFBFCMTokenChanged E.Value
    | OnFBConnectionChanged Bool
