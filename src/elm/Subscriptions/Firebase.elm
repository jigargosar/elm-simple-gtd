module Subscriptions.Firebase exposing (..)

import Firebase.Types exposing (FirebaseMsg(..))
import Ports.Firebase exposing (..)


subscriptions : model -> Sub FirebaseMsg
subscriptions _ =
    Sub.batch
        [ onFirebaseUserChanged OnFBUserChanged
        , onFCMTokenChanged OnFBFCMTokenChanged
        , onFirebaseConnectionChanged OnFBConnectionChanged
        ]
