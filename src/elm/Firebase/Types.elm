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


type FirebaseUser
    = SignedOut
    | SignedIn UserInfo


type alias UserInfo =
    { id : String
    , providerData : List Provider
    }


type alias Provider =
    { displayName : String
    , email : String
    , photoURL : String
    , providerId : String
    , uid : String
    }


type alias FCMToken =
    Maybe String
