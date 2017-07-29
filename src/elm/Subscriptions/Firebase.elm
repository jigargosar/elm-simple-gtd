module Subscriptions.Firebase exposing (..)

import Firebase.Types exposing (..)
import Ports.Firebase exposing (..)


subscriptions : model -> Sub FirebaseMsg
subscriptions _ =
    Sub.batch
        [ onFirebaseUserChanged OnFBUserChanged
        , onFCMTokenChanged OnFBFCMTokenChanged
        , onFirebaseConnectionChanged OnFBConnectionChanged
        ]
